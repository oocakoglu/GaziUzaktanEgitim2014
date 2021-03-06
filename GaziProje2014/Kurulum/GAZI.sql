-- SQL Manager 2008 for SQL Server 3.2.0.2
-- ---------------------------------------
-- Host      : .
-- Database  : GAZI
-- Version   : Microsoft SQL Server  10.0.1600.22


--
-- Definition for contract DEFAULT : 
--

CREATE CONTRACT [DEFAULT] 
  AUTHORIZATION [dbo]
  ([DEFAULT] SENT BY ANY)
GO

--
-- Definition for stored procedure sp_upgraddiagrams : 
--
GO
CREATE PROCEDURE dbo.sp_upgraddiagrams
	AS
	BEGIN
		IF OBJECT_ID(N'dbo.sysdiagrams') IS NOT NULL
			return 0;
	
		CREATE TABLE dbo.sysdiagrams
		(
			name sysname NOT NULL,
			principal_id int NOT NULL,	-- we may change it to varbinary(85)
			diagram_id int PRIMARY KEY IDENTITY,
			version int,
	
			definition varbinary(max)
			CONSTRAINT UK_principal_name UNIQUE
			(
				principal_id,
				name
			)
		);


		/* Add this if we need to have some form of extended properties for diagrams */
		/*
		IF OBJECT_ID(N'dbo.sysdiagram_properties') IS NULL
		BEGIN
			CREATE TABLE dbo.sysdiagram_properties
			(
				diagram_id int,
				name sysname,
				value varbinary(max) NOT NULL
			)
		END
		*/

		IF OBJECT_ID(N'dbo.dtproperties') IS NOT NULL
		begin
			insert into dbo.sysdiagrams
			(
				[name],
				[principal_id],
				[version],
				[definition]
			)
			select	 
				convert(sysname, dgnm.[uvalue]),
				DATABASE_PRINCIPAL_ID(N'dbo'),			-- will change to the sid of sa
				0,							-- zero for old format, dgdef.[version],
				dgdef.[lvalue]
			from dbo.[dtproperties] dgnm
				inner join dbo.[dtproperties] dggd on dggd.[property] = 'DtgSchemaGUID' and dggd.[objectid] = dgnm.[objectid]	
				inner join dbo.[dtproperties] dgdef on dgdef.[property] = 'DtgSchemaDATA' and dgdef.[objectid] = dgnm.[objectid]
				
			where dgnm.[property] = 'DtgSchemaNAME' and dggd.[uvalue] like N'_EA3E6268-D998-11CE-9454-00AA00A3F36E_' 
			return 2;
		end
		return 1;
	END
GO

--
-- Definition for stored procedure sp_renamediagram : 
--
GO
CREATE PROCEDURE dbo.sp_renamediagram
	(
		@diagramname 		sysname,
		@owner_id		int	= null,
		@new_diagramname	sysname
	
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
		declare @DiagIdTarg		int
		declare @u_name			sysname
		if((@diagramname is null) or (@new_diagramname is null))
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end
	
		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT;
	
		select @u_name = USER_NAME(@owner_id)
	
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end
	
		-- if((@u_name is not null) and (@new_diagramname = @diagramname))	-- nothing will change
		--	return 0;
	
		if(@u_name is null)
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @new_diagramname
		else
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @owner_id and name = @new_diagramname
	
		if((@DiagIdTarg is not null) and  @DiagId <> @DiagIdTarg)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end		
	
		if(@u_name is null)
			update dbo.sysdiagrams set [name] = @new_diagramname, principal_id = @theId where diagram_id = @DiagId
		else
			update dbo.sysdiagrams set [name] = @new_diagramname where diagram_id = @DiagId
		return 0
	END
GO

--
-- Definition for stored procedure sp_helpdiagrams : 
--
GO
CREATE PROCEDURE dbo.sp_helpdiagrams
	(
		@diagramname sysname = NULL,
		@owner_id int = NULL
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		DECLARE @user sysname
		DECLARE @dboLogin bit
		EXECUTE AS CALLER;
			SET @user = USER_NAME();
			SET @dboLogin = CONVERT(bit,IS_MEMBER('db_owner'));
		REVERT;
		SELECT
			[Database] = DB_NAME(),
			[Name] = name,
			[ID] = diagram_id,
			[Owner] = USER_NAME(principal_id),
			[OwnerID] = principal_id
		FROM
			sysdiagrams
		WHERE
			(@dboLogin = 1 OR USER_NAME(principal_id) = @user) AND
			(@diagramname IS NULL OR name = @diagramname) AND
			(@owner_id IS NULL OR principal_id = @owner_id)
		ORDER BY
			4, 5, 1
	END
GO

--
-- Definition for stored procedure sp_helpdiagramdefinition : 
--
GO
CREATE PROCEDURE dbo.sp_helpdiagramdefinition
	(
		@diagramname 	sysname,
		@owner_id	int	= null 		
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		set nocount on

		declare @theId 		int
		declare @IsDbo 		int
		declare @DiagId		int
		declare @UIDFound	int
	
		if(@diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		revert; 
	
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname;
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId ))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end

		select version, definition FROM dbo.sysdiagrams where diagram_id = @DiagId ; 
		return 0
	END
GO

--
-- Definition for stored procedure sp_dropdiagram : 
--
GO
CREATE PROCEDURE dbo.sp_dropdiagram
	(
		@diagramname 	sysname,
		@owner_id	int	= null
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
	
		if(@diagramname is null)
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end
	
		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT; 
		
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end
	
		delete from dbo.sysdiagrams where diagram_id = @DiagId;
	
		return 0;
	END
GO

--
-- Definition for stored procedure sp_creatediagram : 
--
GO
CREATE PROCEDURE dbo.sp_creatediagram
	(
		@diagramname 	sysname,
		@owner_id		int	= null, 	
		@version 		int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
	
		declare @theId int
		declare @retval int
		declare @IsDbo	int
		declare @userName sysname
		if(@version is null or @diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID(); 
		select @IsDbo = IS_MEMBER(N'db_owner');
		revert; 
		
		if @owner_id is null
		begin
			select @owner_id = @theId;
		end
		else
		begin
			if @theId <> @owner_id
			begin
				if @IsDbo = 0
				begin
					RAISERROR (N'E_INVALIDARG', 16, 1);
					return -1
				end
				select @theId = @owner_id
			end
		end
		-- next 2 line only for test, will be removed after define name unique
		if EXISTS(select diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @diagramname)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end
	
		insert into dbo.sysdiagrams(name, principal_id , version, definition)
				VALUES(@diagramname, @theId, @version, @definition) ;
		
		select @retval = @@IDENTITY 
		return @retval
	END
GO

--
-- Definition for stored procedure sp_alterdiagram : 
--
GO
CREATE PROCEDURE dbo.sp_alterdiagram
	(
		@diagramname 	sysname,
		@owner_id	int	= null,
		@version 	int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
	
		declare @theId 			int
		declare @retval 		int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
		declare @ShouldChangeUID	int
	
		if(@diagramname is null)
		begin
			RAISERROR ('Invalid ARG', 16, 1)
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();	 
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		revert;
	
		select @ShouldChangeUID = 0
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		
		if(@DiagId IS NULL or (@IsDbo = 0 and @theId <> @UIDFound))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end
	
		if(@IsDbo <> 0)
		begin
			if(@UIDFound is null or USER_NAME(@UIDFound) is null) -- invalid principal_id
			begin
				select @ShouldChangeUID = 1 ;
			end
		end

		-- update dds data			
		update dbo.sysdiagrams set definition = @definition where diagram_id = @DiagId ;

		-- change owner
		if(@ShouldChangeUID = 1)
			update dbo.sysdiagrams set principal_id = @theId where diagram_id = @DiagId ;

		-- update dds version
		if(@version is not null)
			update dbo.sysdiagrams set version = @version where diagram_id = @DiagId ;

		return 0
	END
GO

--
-- Definition for user-defined function fn_diagramobjects : 
--
GO
CREATE FUNCTION dbo.fn_diagramobjects() 
	RETURNS int
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		declare @id_upgraddiagrams		int
		declare @id_sysdiagrams			int
		declare @id_helpdiagrams		int
		declare @id_helpdiagramdefinition	int
		declare @id_creatediagram	int
		declare @id_renamediagram	int
		declare @id_alterdiagram 	int 
		declare @id_dropdiagram		int
		declare @InstalledObjects	int

		select @InstalledObjects = 0

		select 	@id_upgraddiagrams = object_id(N'dbo.sp_upgraddiagrams'),
			@id_sysdiagrams = object_id(N'dbo.sysdiagrams'),
			@id_helpdiagrams = object_id(N'dbo.sp_helpdiagrams'),
			@id_helpdiagramdefinition = object_id(N'dbo.sp_helpdiagramdefinition'),
			@id_creatediagram = object_id(N'dbo.sp_creatediagram'),
			@id_renamediagram = object_id(N'dbo.sp_renamediagram'),
			@id_alterdiagram = object_id(N'dbo.sp_alterdiagram'), 
			@id_dropdiagram = object_id(N'dbo.sp_dropdiagram')

		if @id_upgraddiagrams is not null
			select @InstalledObjects = @InstalledObjects + 1
		if @id_sysdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 2
		if @id_helpdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 4
		if @id_helpdiagramdefinition is not null
			select @InstalledObjects = @InstalledObjects + 8
		if @id_creatediagram is not null
			select @InstalledObjects = @InstalledObjects + 16
		if @id_renamediagram is not null
			select @InstalledObjects = @InstalledObjects + 32
		if @id_alterdiagram  is not null
			select @InstalledObjects = @InstalledObjects + 64
		if @id_dropdiagram is not null
			select @InstalledObjects = @InstalledObjects + 128
		
		return @InstalledObjects 
	END
GO

--
-- Definition for table Test4 : 
--

CREATE TABLE [dbo].[Test4] (
  [Kolon1] nvarchar(50) COLLATE Turkish_CI_AS NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Test3 : 
--

CREATE TABLE [dbo].[Test3] (
  [Kolon1] nvarchar(50) COLLATE Turkish_CI_AS NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Test2 : 
--

CREATE TABLE [dbo].[Test2] (
  [Kolon1] nvarchar(50) COLLATE Turkish_CI_AS NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Test1 : 
--

CREATE TABLE [dbo].[Test1] (
  [Kolon1] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [Kolon2] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [Kolon3] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [Kolon4] nvarchar(50) COLLATE Turkish_CI_AS NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Temalar : 
--

CREATE TABLE [dbo].[Temalar] (
  [TemaId] int IDENTITY(1, 1) NOT NULL,
  [TemaAdi] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [TemaPath] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [TemaThumbnailPath] nvarchar(500) COLLATE Turkish_CI_AS NULL
)
ON [PRIMARY]
GO

--
-- Definition for table sysdiagrams : 
--

CREATE TABLE [dbo].[sysdiagrams] (
  [name] sysname COLLATE Turkish_CI_AS NOT NULL,
  [principal_id] int NOT NULL,
  [diagram_id] int IDENTITY(1, 1) NOT NULL,
  [version] int NULL,
  [definition] varbinary(max) NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Sorular : 
--

CREATE TABLE [dbo].[Sorular] (
  [SoruId] int IDENTITY(1, 1) NOT NULL,
  [OgretmenDersId] int NULL,
  [SoruIcerik] nvarchar(max) COLLATE Turkish_CI_AS NULL,
  [SoruKonu] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [SoruResim] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [CvpSayisi] int NULL,
  [DogruCvp] int NULL,
  [Cvp1] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [Cvp2] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [Cvp3] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [Cvp4] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [Cvp5] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [EkleyenId] int NULL,
  [KayitTrh] datetime NULL
)
ON [PRIMARY]
GO

--
-- Definition for table SinavDetay : 
--

CREATE TABLE [dbo].[SinavDetay] (
  [SinavDetayId] int IDENTITY(1, 1) NOT NULL,
  [SinavId] int NULL,
  [SoruId] int NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Sinav_Detay : 
--

CREATE TABLE [dbo].[Sinav_Detay] (
  [Id] bigint IDENTITY(1, 1) NOT NULL,
  [SinavId] bigint NULL,
  [SorularId] bigint NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Sinav : 
--

CREATE TABLE [dbo].[Sinav] (
  [SinavId] int IDENTITY(1, 1) NOT NULL,
  [OgretmenDersId] int NULL,
  [SinavAdi] nvarchar(250) COLLATE Turkish_CI_AS NULL,
  [SinavAciklama] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [Sure] int NULL,
  [BaslangicTarihi] datetime NULL,
  [BitisTarihi] datetime NULL,
  [KayitTrh] datetime NULL,
  [EkleyenId] int NULL,
  [UstOnay] bit NULL
)
ON [PRIMARY]
GO

--
-- Definition for table OgretmenDersler : 
--

CREATE TABLE [dbo].[OgretmenDersler] (
  [OgretmenDersId] int IDENTITY(1, 1) NOT NULL,
  [OgretmenId] int NULL,
  [DersId] int NULL,
  [OgretmenOnayi] bit NULL,
  [UstOnay] bit NULL
)
ON [PRIMARY]
GO

--
-- Definition for table OgrenciSinavDetay : 
--

CREATE TABLE [dbo].[OgrenciSinavDetay] (
  [OgrenciSinavDetayId] int IDENTITY(1, 1) NOT NULL,
  [OgrenciSinavId] int NULL,
  [SoruId] int NULL,
  [OgrenciCvp] int NULL
)
ON [PRIMARY]
GO

--
-- Definition for table OgrenciSinav : 
--

CREATE TABLE [dbo].[OgrenciSinav] (
  [OgrenciSinavId] int IDENTITY(1, 1) NOT NULL,
  [SinavId] int NULL,
  [OgrenciId] int NULL,
  [BaslamaZamani] datetime NULL,
  [BitisZamani] datetime NULL,
  [IPNumarasi] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [SonGuncellemeTarihi] datetime NULL,
  [ToplamOnlineSure] int NULL
)
ON [PRIMARY]
GO

--
-- Definition for table OgrenciDersler : 
--

CREATE TABLE [dbo].[OgrenciDersler] (
  [OgrenciDersId] int IDENTITY(1, 1) NOT NULL,
  [OgretmenDersId] int NULL,
  [OgrenciId] int NULL,
  [OgrenciOnayi] bit NULL,
  [UstOnay] bit NULL,
  [KayitTarihi] datetime NULL,
  [OnayTarihi] datetime NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Ogr_Sinav : 
--

CREATE TABLE [dbo].[Ogr_Sinav] (
  [Id] bigint IDENTITY(1, 1) NOT NULL,
  [KullaniciId] int NULL,
  [SorularId] bigint NULL,
  [OgrCvp] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [CvpTrh] datetime NULL
)
ON [PRIMARY]
GO

--
-- Definition for table KullaniciTipleri : 
--

CREATE TABLE [dbo].[KullaniciTipleri] (
  [KullaniciTipId] int IDENTITY(1, 1) NOT NULL,
  [KullaniciTipAdi] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [KullaniciTipAciklama] nvarchar(250) COLLATE Turkish_CI_AS NULL,
  [KullaniciTipDurum] bit NULL
)
ON [PRIMARY]
GO

--
-- Definition for table KullaniciLogDetail : 
--

CREATE TABLE [dbo].[KullaniciLogDetail] (
  [Id] int IDENTITY(1, 1) NOT NULL,
  [KullaniciId] int NULL,
  [HareketId] int NULL,
  [HareketTarihi] datetime NULL,
  [IpNumarasi] nvarchar(50) COLLATE Turkish_CI_AS NULL
)
ON [PRIMARY]
GO

--
-- Definition for table KullaniciLogAna : 
--

CREATE TABLE [dbo].[KullaniciLogAna] (
  [Id] int IDENTITY(1, 1) NOT NULL,
  [KullaniciId] int NULL,
  [ToplamSure] time(7) NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Kullanicilar : 
--

CREATE TABLE [dbo].[Kullanicilar] (
  [KullaniciId] int IDENTITY(1, 1) NOT NULL,
  [KullaniciAdi] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [KullaniciSifre] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [Adi] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [Soyadi] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [KullaniciTipi] int NULL,
  [DogumTarihi] datetime NULL,
  [Cinsiyet] int NULL,
  [CepTel] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [EvTel] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [Email] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [IlKodu] int NULL,
  [IlceKodu] int NULL,
  [Adres] nvarchar(1500) COLLATE Turkish_CI_AS NULL,
  [Resim] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [KayitTarihi] datetime NULL,
  [Onay] bit NULL,
  [DokumanAdres] nvarchar(500) COLLATE Turkish_CI_AS NULL
)
ON [PRIMARY]
GO

--
-- Definition for table KullaniciFormlar : 
--

CREATE TABLE [dbo].[KullaniciFormlar] (
  [Id] int IDENTITY(1, 1) NOT NULL,
  [KullaniciTipiId] int NULL,
  [FormId] int NULL,
  [FormYetki] bit NULL
)
ON [PRIMARY]
GO

--
-- Definition for table KullaniciDersler : 
--

CREATE TABLE [dbo].[KullaniciDersler] (
  [Id] int IDENTITY(1, 1) NOT NULL,
  [KullaniciId] int NULL,
  [DersId] int NULL,
  [KullaniciOnayi] bit NULL,
  [UstOnay] bit NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Ilce : 
--

CREATE TABLE [dbo].[Ilce] (
  [IlceKodu] int NOT NULL,
  [IlceAdi] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [IlKodu] int NULL,
  [IlAdi] nvarchar(30) COLLATE Turkish_CI_AS NULL,
  [IegmIlceKodu] nvarchar(30) COLLATE Turkish_CI_AS NULL,
  [IlceSon] nvarchar(50) COLLATE Turkish_CI_AS NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Il : 
--

CREATE TABLE [dbo].[Il] (
  [IlKodu] int NOT NULL,
  [IlAdi] nvarchar(50) COLLATE Turkish_CI_AS NULL
)
ON [PRIMARY]
GO

--
-- Definition for table HareketTipleri : 
--

CREATE TABLE [dbo].[HareketTipleri] (
  [HareketId] int NOT NULL,
  [HareketAdi] nvarchar(50) COLLATE Turkish_CI_AS NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Formlar : 
--

CREATE TABLE [dbo].[Formlar] (
  [Id] int IDENTITY(1, 1) NOT NULL,
  [PId] int NULL,
  [PFormBaslik] nvarchar(250) COLLATE Turkish_CI_AS NULL,
  [FormBaslik] nvarchar(250) COLLATE Turkish_CI_AS NULL,
  [FormAdi] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [FormAciklama] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [FormImageUrl] nvarchar(250) COLLATE Turkish_CI_AS NULL
)
ON [PRIMARY]
GO

--
-- Definition for table EFormlar : 
--

CREATE TABLE [dbo].[EFormlar] (
  [Id] int IDENTITY(1, 1) NOT NULL,
  [PId] int NULL,
  [PFormBaslik] nvarchar(250) COLLATE Turkish_CI_AS NULL,
  [FormBaslik] nvarchar(250) COLLATE Turkish_CI_AS NULL,
  [FormAdi] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [FormAciklama] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [FormIcon] nvarchar(20) COLLATE Turkish_CI_AS NULL
)
ON [PRIMARY]
GO

--
-- Definition for table DuyuruKullanicilar : 
--

CREATE TABLE [dbo].[DuyuruKullanicilar] (
  [Id] int IDENTITY(1, 1) NOT NULL,
  [DuyuruId] int NULL,
  [KullaniciTipiId] int NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Duyurular : 
--

CREATE TABLE [dbo].[Duyurular] (
  [DuyuruId] int IDENTITY(1, 1) NOT NULL,
  [DuyuruAdi] nvarchar(250) COLLATE Turkish_CI_AS NULL,
  [DuyuruIcerik] nvarchar(3000) COLLATE Turkish_CI_AS NULL,
  [DuyuruTarihi] datetime NULL,
  [DuyuruKayitEdenId] int NULL
)
ON [PRIMARY]
GO

--
-- Definition for table Dersler : 
--

CREATE TABLE [dbo].[Dersler] (
  [DersId] int IDENTITY(1, 1) NOT NULL,
  [DersAdi] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [DersAciklama] nvarchar(50) COLLATE Turkish_CI_AS NULL,
  [DersDurum] bit NULL
)
ON [PRIMARY]
GO

--
-- Definition for table DersIcerikler : 
--

CREATE TABLE [dbo].[DersIcerikler] (
  [IcerikId] int IDENTITY(1, 1) NOT NULL,
  [IcerikPId] int NULL,
  [OgretmenDersId] int NULL,
  [IcerikAdi] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [IcerikTip] int NULL,
  [IcerikText] nvarchar(max) COLLATE Turkish_CI_AS NULL,
  [IcerikUrl] nvarchar(500) COLLATE Turkish_CI_AS NULL,
  [DersSira] int NULL,
  [IconUrl] nvarchar(150) COLLATE Turkish_CI_AS NULL,
  [EkleyenId] int NULL,
  [KayitTarihi] datetime NULL
)
ON [PRIMARY]
GO

--
-- Data for table dbo.DersIcerikler  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[DersIcerikler] ON
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (1, NULL, 28, N'Kümeler', 1, NULL, NULL, NULL, N'~/Style/ArsivAna.png', 1, '20140510')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (2, 1, 28, N'Kümelerde Birleşim', 1, NULL, NULL, NULL, N'~/Style/folder.png', 1, '20140510')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (3, 1, 28, N'Kümelerde Kesişim', 1, NULL, NULL, NULL, N'~/Style/folder.png', 1, '20140510')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (4, 1, 28, N'Kümelerde Fark', 1, N'<table>
    <tbody>
        <tr>
            <td>
            <img alt="" src="http://img.webme.com/pic/m/matemaatik/kum11.gif" />
            </td>
            <td><span style="padding: 0px; margin: 0px; text-align: justify; font-size: 13.5pt; color: #000000;"><span style="padding: 0px; margin: 0px; color: #c00000;"><strong>K&uuml;melerin G&ouml;sterim Şekilleri:</strong><br style="padding: 0px; margin: 0px;" />
            </span><br style="padding: 0px; margin: 0px;" />
            K&uuml;melerin 3 &ccedil;eşit&nbsp;</span><span style="text-align: justify; font-size: 13.5pt; padding: 0px; margin: 0px; color: #000000;">g&ouml;sterimi vardır.<br style="padding: 0px; margin: 0px;" />
            <strong>1)</strong> Liste y&ouml;ntemi: K&uuml;menin elemanları aralarına virg&uuml;l konularak parantez i&ccedil;inde yazılır. A= (1,2,3,4,5)<br style="padding: 0px; margin: 0px;" />
            <strong>2)</strong> Şema y&ouml;ntemi: K&uuml;menin elemanları yanlarına nokta koyularak şema veya kapalı bir şekil i&ccedil;erisine yazılır.<br style="padding: 0px; margin: 0px;" />
            </span><span style="text-align: justify; font-size: 13.5pt; padding: 0px; margin: 0px; color: #000000;">3) Ortak &ouml;zellik y&ouml;ntemi: K&uuml;menin elemanlarının ortak &ouml;zellikleri kısaltılarak parantez i&ccedil;ine yazılır.&nbsp;<br style="padding: 0px; margin: 0px;" />
            A=( 10''dan k&uuml;&ccedil;&uuml;k tek sayılar)<br style="padding: 0px; margin: 0px;" />
            </span><span style="padding: 0px; margin: 0px; text-align: justify; font-size: 13.5pt; color: #000000;"><br style="padding: 0px; margin: 0px;" />
            <span style="padding: 0px; margin: 0px; color: #c00000;"><strong>Alt K&uuml;me:</strong></span>&nbsp;Alt k&uuml;me demek&nbsp;bir k&uuml;me diğer k&uuml;menin i&ccedil;inde olacak.&nbsp;</span><span style="text-align: justify; font-size: 13.5pt; padding: 0px; margin: 0px; color: #000000;">&Ouml;rneğin haftanın g&uuml;nleri&nbsp;</span><span style="padding: 0px; margin: 0px; text-align: justify; font-size: 13.5pt; color: #000000;">k&uuml;mesinde Salı g&uuml;n&uuml; alt k&uuml;medir &ccedil;&uuml;nk&uuml; haftanın i&ccedil;indedir.Haftanın g&uuml;nleri k&uuml;me,salı g&uuml;n&uuml; alt k&uuml;medir.Kapsar tam tersi demektir.<br style="padding: 0px; margin: 0px;" />
            Her k&uuml;me kendisinin alt k&uuml;mesidir.<br style="padding: 0px; margin: 0px;" />
            A=(1,2,3,4,5,6) K&uuml;mesinin bazı alt k&uuml;meleri (1),(2),(1,2,5),(2,4,5,6),(1,2,3,4,5,6) .......</span><br />
            <br />
            </td>
        </tr>
    </tbody>
</table>', NULL, NULL, N'~/Style/folder.png', 1, '20140528 23:27:45.740')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (5, NULL, 28, N'Sayılar', 1, NULL, NULL, NULL, N'~/Style/ArsivAna.png', 1, '20140510')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (6, 5, 28, N'Doğal Sayılar', 1, NULL, NULL, NULL, N'~/Style/folder.png', 1, '20140510')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (7, 5, 28, N'Rayonel Sayılar', 1, NULL, NULL, NULL, N'~/Style/folder.png', 1, '20140510')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (8, 5, 28, N'Ondalık Sayılar', 1, NULL, NULL, NULL, N'~/Style/folder.png', 1, '20140510')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (9, NULL, 28, N'Bölünebilme\Ebob-ekok', 1, NULL, NULL, NULL, N'~/Style/ArsivAna.png', 1, '20140510')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (10, 9, 28, N'En büyük ortak bölen', 1, NULL, NULL, NULL, N'~/Style/folder.png', 1, '20140510')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (11, 9, 28, N'En Küçük Ortak Bölen', 1, NULL, NULL, NULL, N'~/Style/folder.png', 1, '20140510')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (13, NULL, 28, N'Denklemler', 1, N'Denklem test mest', NULL, NULL, N'~/Style/ArsivAna.png', 1, '20140511 14:50:37.267')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (14, 13, 28, N'Bir bilinmeyenli denklemler', 1, N'2013 Yılı Güncel Bakanlar Listesi:

Adalet Bakanı: Sadullah Ergin
Dış İşleri Bakanı: Ahmet Davutoğlu
Maliye Bakanı: Mehmet Şimşek
Çalışma ve Sosyal Güvenlik Bakanı: Faruk Çelik
Enerji ve Tabii Kaynaklar Bakanı: Taner Yıldız
Gıda Tarım ve Hayvancılık Bakanı: Mehmet Mehdi Eker
Gençlik ve Spor Bakanı: Suat Kılıç
Milli Savunma Bakanı: İsmet Yılmaz
Gümrük ve Ticaret Bakanı: Hayati Yazıcı
Kültür ve Turizm Bakanı: Ömer Çelik
Kalkınma Bakanı: Cevdet Yılmaz
Ekonomi Bakanı: Mehmet Zafer Çağlayan
Ulaştırma Denizcilik ve Haberleşme Bakanı: Binali Yıldırım
Çevre ve Şehircilik Bakanı: Erdoğan Bayraktar
Milli Eğitim Bakanı: Nabi Avcı
Sağlık Bakanı: Mehmet Müezzinoğlu
Orman ve Su İşleri Bakanı: Veysel Eroğlu
Bilim Sanayi ve Teknoloji Bakanı: Nihat Ergün
Avrupa Birliği Bakanı: Egemen Bağış
Aile ve Sosyal Politikalar Bakanı: Fatma Şahin
İçişleri Bakanı: Muammer Güler

Cumhurbaşkanları Listesi:
1.	Mustafa Kemal Atatürk: 29 Ekim 1923 – 10 Kasım 1938 (4 dönem, CHP)
2.	İsmet İnönü: 11 Kasım 1938 – 22 Mayıs 1950 (4 dönem, CHP)
3.	Celal Bayar: 22 Mayıs 1950 – 1 Kasım 1960 (3 dönem, Demokrat Parti)
4.	Cemal Gürsel: 27 Mayıs 1960 – 28 Mart 1966 (2 dönem, Bağımsız)
5.	Cevdet Sunay: 28 Mart 1966 – 28 Mart 1973 (1 dönem, Bağımsız)
6.	Fahri Korutürk: 6 Nisan 1973 – 6 Nisan 1980 (1 dönem, Bağımsız)
7.	Kenan Evren: 9 Kasım 1982 – 9 Kasım 1989 (1 dönem, Bağımsız)
8.	Turgut Özal: 31 Ekim 1989 – 17 Nisan 1993 (1 dönem, Anavatan Partisi)
9.	Süleyman Demirel: 16 Mayıs 1993 – 16 Mayıs 2000 (1 dönem, Doğru Yol Partisi)
10.	Ahmet Necdet Sezer: 16 Mayıs 2000 – 28 Ağustos 2007 (1 dönem, Bağımsız)
11.	Abdullah Gül: 28 Ağustos 2007 – Halen görevde (Adalet ve Kalkınma Partisi)
Dünyanın 7 harikası:
1-Kurtarıcı İsa Heykeli – Brezilya
2-Manchu Pichu Şehri – Peru
3- Tac Mahal – Hindistan
4-Chicken İtza Piramidi – Meksika
5- Çin Seddi – Çin
6- Petra Antik Kenti – Ürdün
7- Colisseum – İtalya
Online İKM Mülakatı:www.katipler.net/mulakat
Avrupa Başkentleri:
Almanya : Berlin
Andorra : Andorra La Vella
Arnavutluk : Tiran
Avusturya : Viyana
Belarus : Minsk
Belçika : Brüksel
Bosna ve Hersek : Saraybosna
Bulgaristan : Sofya
BBritanya ve Kİrlanda : Londra
Çek Cumhuriyeti : Prag
Danimarka : Kopenhang
Estonya : Tailin
Finlandia : Helsinki
Fransa : Paris
Hırvatistan : Zagrep
Hollanda : Amsterdam
İrlanda Cumhuriyeti : Dublin
İspanya : Madrid
İsveç : Stockholm
İsviçre : Bern
İtalya : Roma
İzlanda : Reykjavik
KKTC : Lefkoşe
GKRY : Nicosia
Lettonya : Riga
Liechtenstein Prensliği : Vaduz
Litvanya : Vilnus
Lüksemburg : Lüksemburg
Macaristan : Budapeşte
Makedonya : Üsküp
Malta : Valletta
Moldova : Kişinev
Monako : Monako
Norveç : Oslo
Polonya : Varşova
Portekiz : Lizbon
Romanya : Bükreş
Rusya Federasyonu : Moskova
San Marino Cumhuriyeti : San Marino
Sırbistan-Karadağ : Belgrad
Slovakya : Bratislava
Slovenya : Ljubljana
Türkiye : Ankara
Ukrayna : Kiev
Yunanistan : Atina
Online İKM Mülakatı:www.katipler.net/mulakat



Türkiye’nin enleri ve ilkleri:

-İlk hava şehidimiz Fethi Bey’dir.
-İlk Türk uçağı Mavi Işık’tır(Kayseri/1979)
-Dünyanın ilk ve tek cellat mezarı İstanbul Eyüp’te yer alır.
-Nargile Osmanlı’ya ilk olarak Yavuz Sultan Selim zamanında Hindistan’dan getirildi.
-Yerleşim yerine yapılan ilk baraj Denizli Gökpınar Barajı’dır.
-Türkiye’de ilk nüfus sayimi 1927 yılında yapıldı.
-En fazla yağış alan ilimiz Rize’dir.
-TBMM’nin ilk baskani Fethi Okyar’dir.
-Ilk basbakanimiz Ismet Inönü’dür.
-En büyük adamiz Gökçeada’dir.(Çanakkale)
-Ingilizce ile egitime baslayan ilk Türk okulu Ankara TED Koleji’dir.(1954)
-Türkiye’de özürlülere yönelik ilk otel Antalya’da hizmete girmiştir
-Türkiye’nin ilk özel hayvanat bahçesi Bogaziçi Hayvanat Bahçesi’dir.(Izmit-Darica)
-Türkiye Cumhuriyeti’nin ilk anayasası 1924 anayasasıdır.
-Türkiye’nin en çok otel bulunan yeri Eminönü’dür.
-Türkiye’de feribot ile taşımacılık yapılan tek göl Van Gölü’dür.
-Kıbrıs Barış Harekatı esnasında uçaklarımızın yanlışlıkla vurduğu gemimiz Kocatepe’dir.
-Türkiye’nin ilk kadın bakanı Türkan Akyol’dur.
-İlk şah tuğrası Yavuz Sultan Selim’in tuğrasında görülmeye başlanmıştır.
-İlk Türkçe ezan İstanbul Fatih Camii’nde okundu.
-Türkiye’nin ilk televizyon yayını İstanbul’dan yapıldı.
-Cumhuriyet döneminde kurulan ilk muhalefet partisi Terakkiperver Cumhuriyet Fırka’sır.
-Türkiye’de ilk politika okulu Nazif Ülken tarafından kurulmuştur.
-Türkiye’de en fazla milletvekili seçilen İsmet İnönü’dür.(14 defa)
-Ramazan çadırı ilk kez 1995 yılında Üsküdar Belediyesi tarafından kuruldu.
-Cumhuriyet tarihinin en uzun süreli azınlık hükümeti Anasol-D hükümetidir.
-Türkiye’deki ilk mali kurum Emniyet Sandığı’dır.
-Türkiye’nin bilinen ilk erkek hemşiresi Murat Bektaş’tır.
-Türkiye’nin ilk haber ajansı Anadolu Ajansı’dır.(1920)
-Türkiye’nin ilk sınır ötesi harekâtı Kıbrıs çıkarmasıdır.
-Türkiye’de kurulan ilk parti C.H.P’dir.
-Latin alfabesine resmi olarak ilk geçen Türk devleti Azerbaycan’dır.
-Türkiye’nin en düşük gelir elde edilen ili Muş’tur.
-Yüzölçümü itibariyle en küçük komşumuz Ermenistan’dır.
-Türkiye Büyük Millet Meclisi’nin ilk başkanı M.Kemal’dir.
-Türkiye’de baskı tekniğini ilk kez İbrahim Müteferrika kurmuştur.
-İlk TSE belgesi Yıldırım Bayezid devrinde çıkarılmıştır.
-Türkiye’nin en yüksek minaresi Selimiye Camisinde bulunur.
-Türkiye Cumhuriyeti devletini ilk kabul eden devlet Ermenistan’dır.
-Osmanlı Devleti’nin ilk bankası Banka-i Der Saadet’tir.(İstanbul Bankası)
-Türkiye’de ilk uçak fabrikası Kayseri’de açıldı.
-Kelaynak kuşları ülkemizde sadece Urfa’nın Birecik ilçesinde bulunur.
-En işlek kara sınırımız Yunanistan sınırıdır.
-Türkiye’de öldürülen ilk başbakan Nihat Erim’dir.
-Türkiye’de ilk İngilizce gazete İlknur Çevik tarafından çıkarılmıştır.
-Türkiye’nin ilk haber spikeri Zafer Cilasun’dur.
-Mallarda kalite arayan ilk millet Türkler’dir.
-Türkiye dışarıya ilk olarak G.Kore’ye asker göndermiştir.
-Türkiye’nin en eski şehri Hakkari’dir.
-Türkiye’de taşkömürünü ilk defa Uzun Mehmet bulmuştur.
-Konya Türkiye’nin en uzun karayolu ağına sahiptir.
-Türkiye’nin en kalabalık mezarlığı İstanbul Karacaahmet Mezarlığı’dır.
-Dünyada en fazla konuşulan diller sırasıyla şöyledir: Çince, Hintçe, İngilizce, İspanyolca ve Türkçe’dir.
-Türkiye’de ilk milletvekili seçimleri I.Meşrutiyet’de yapıldı.
-Ege Bölgesi’nde en uzun kıyılara sahip ilimiz Muğla’dır.
-Karadeniz’in en yüksek dağı Kaçkar Dağı’dır.
-Taşkömürü ilk defa Zonguldak’ta çıkarılmıştır.
-Türkiye’de petrol arama çalışmaları ilk defa İskenderun’da yapılmıştır.
-Türkiye’nin en zengin boksit yatakları Seydişehir’de bulunur.
-Türkiye’de heyelan en çok kış mevsiminde görülür.
-Türkiye’nin doğusu ile batısı arasında 76 dakikalık zaman farkı vardır.
-Türkiye’nin ilk turistik yerleşim yeri Çeşme’dir.
-Kümes hayvancılığı en çok Marmara Bölgesi’de farklıdır.
-Türkiye’nin en doğu ucunda Iğdır ili bulunur.
-Türkiye’nin çay yetiştirilen tek yöresi D.Karadeniz’dir.
-Türkiye’de rüzgarın en etkili olduğu yer İç Anadolu’dur.
-Türkiye’nin en az göç veren bölgesi Marmara Bölgesidir.
-Türkiye’nin en az ormana sahip bölgesi G.Anadolu Bölgesi’dir.
-İç Anadolu Bölgesi’nin en yüksek yeri Erciyes Dağı’dır.
-Ulaşım yapılabilinen tek akarsuyumuz Bartın Çayı’dır.
-Ülkemizde ilk dokuma fabrikası Nazilli’de açılmıştır.
-Ülkemizde ilk şeker fabrikası Uşak’ta açılmıştır.
-Ülkemizde ilk demir-çelik fabrikası Karabük’te açılmıştır.
-Kayısı,fındık,çay üretiminde ülkemiz ilk sırada yer alır.
-Dünya bor rezervlerin %70′i ülkemizde yer alır.
-Ülkemizde ipek böcekçiliği en fazla Marmara Bölgesi’nde yapılır.
-Türkiye’nin en fazla kara sınırı Suriye ile(877),en az kara sınırı ise Nahçıvan iledir(10)
-Ege kıyıları en uzun kıyımızdır.
-Ülkemizin en büyük gölü Van Gölü’dür.
-Türkiye’nin en uzun akarsuyu,Kızılırmak’tır.
-Zonguldak kömür yatakları birinci zamanda oluşmuştur.
-Çanakkale ve İstanbul boğazları dördüncü zamanda oluşmuştur.
-Kıyılarımıza en yakın ada Midilli Adası’dır.
-Türkiye dışında Türk bayrağının dalgalandığı tek kale Caber Kalesi’dir

DÜNYA’NIN EN’LERİ:
Dünyanın en yüksek şelalesi: Angel-Venezuela–1.000 m.
Dünyanın en büyük nehri: Nil-Afrika
Dünyanın en yüksek dağı: Everest-Asya–8.848 m.
Dünyanın en büyük çölü: Büyük Sahra Çölü-Orta/Kuzey Afrika
Dünyanın en büyük yanardağı: Tambora-Endonezya
Dünyanın en büyük mağarası: Carlsbad Mağarası-New Mexico, ABD
Dünyanın en büyük gölü: Hazar Denizi-Orta Asya–394.299 km²
Dünyanın en büyük adası: Grönland-Kuzey Atlantik–2.175.597 km²
Dünyanın en sıcak yeri: Al’Aziziyah-Libya–57,7 C
Dünyanın en soğuk yeri: Vostock II- -89,2 C
Dünyanın en kalabalık ülkesi: Çin–1.237.000.000 kişi
Dünyanın en geniş ülkesi: Rusya–10.610.083 km²
Dünyanın en küçük ülkesi: Vatikan–0.272 km².
Dünyanın en kalabalık şehri: Tokyo-Japonya–26.500.000 kişi
Dünyanın en uzun binası: Suyong Bay Tower-Pusan(Güney Kore): 88 kat 462 m.
Dünyanın en uzun demiryolu tüneli: Seikan-Japonya–53,9 km.
Dünyanın en uzun karayolu tüneli: St.Gotthard-İsviçre-16.4 km.
Dünyanın en uzun kanalı: Panama kanalı-Panama–81,5 km.
Dünyanın en uzun köprüsü: Akashi-Japonya–1.990 m.
Dünyada en çok konuşulan dil: Çince (mandarin)-885.000.000 kişi
Dünyanın en çok ülke ile sınırı olan ülke: Çin (15 ülke ile sınırı var)
Dünyanın en yüksek yerleşim yeri: Webzhuan, Çin-Deniz seviyesinden 5.090 m. Yukarıda
Dünyanın en alçak yerleşim yeri: Calipatria, Kaliforniya, ABD – deniz seviyesinin 54 mt. Altında
Dünyanın en uzun kesintisiz sınırı: ABD-Kanada sınırı.


İnfaz Koruma Memuru (Gardiyan) Nedir ?
Cezaevi ve ıslah evlerinde barındırılan suçluların ihtiyaçlarını karşılayan ve bunların ıslahını sağlayarak topluma yeniden kazandırılmasına yardım eden meslek elemanıdır. Eski adıyla gardiyan yeni adıyla infaz koruma memurudur.
İnfaz Koruma Memurunun Görevleri Nelerdir?
Cezaevine giren tutuklu ve hükümlülerin üzerini arar ve taşıdıkları kıymetli eşyayı emniyet altında bulundurur.
Cezaevinde bulunan tutuklu ve hükümlüler hakkında bir takım kayıtları tutar.
Tutuklu ve hükümlüleri koğuşlarına götürerek koğuş kapılarını kilitler.
Koğuşları belirli periyotlarla kontrol eder, çalışan tutuklulara nezaret eder.
Kapı, pencere ve bahçe kapılarının iyi bir şekilde kapatılıp kapatılmadığını ve kaçma girişimiyle ilgili herhangi bir çalışma olup olmadığını muayene ve tespit eder.
Tutuklu ve hükümlüleri yemek, banyo ihtiyaçlarını , revire çıkarma, görüşlere götürülüp getirme, mahkemeye hazırlama, tıraş, kantin ihtiyaçlarının temini, yöneticilerle görüştürülmesi işlemini yapar.
Günde en az 3 defa hükümlülerin ve tutukluların sayımını yapar.
Cezaevlerinde çıkabilecek olaylara anında müdahale ederek olayın büyümesini engeller ve sükunetin devamını sağlar.
Cezaevinde kısmi ve genel aramaları yaparak bulundurulması ve girmesi yasak olan maddelerin girişine engel olur.
Ağır ceza merkezi olmayan (kaza ceza evi) yerlerde katip, idari memurunun bulunmadığı ceza evlerinde sevk ve idareden bütün olarak sorumludur.
Cezaevinin temizliğinden sorumludur.
Cezaevi Müdürünün Görevleri Nelerdir?
a) Kurum personeli üzerinde mevzuatın öngördüğü şekilde gözetim ve denetim hakkını kullanmak,
b) Kurum personeline verilen yazılı veya sözlü emirlerin yerine getirilip getirilmediğini izlemek ve denetlemek,
c) Mevzuat ve yetkili mercilerce verilen emirler çerçevesinde kurumun genel idare ve işyurduna ait hesap işlerinin yürütülmesini ve denetimini yapmak,
d) Hükümlülerin iyileştirilmesi, bilgilerinin artırılması, atölye çalışmaları, kişisel uğraşlarının düzenlenmesi ve geliştirilmesinin sağlanması bakımından mevzuat hükümlerini uygulamak ve sağlık durumlarıyla yakından ilgilenmek,
e) Kamu kurum ve kuruluşları ile bakanlıklar tarafından istenilen istatistiki bilgi ve belgelerin hazırlanmasını sağlamak ve Cumhuriyet başsavcılığına sunmak,
f) Haftada en az bir defa olmak üzere gündüzleri, on beş günde en az bir defa olmak üzere de geceleri kurumun bütün faaliyetlerini tetkik ederek, işlerin mevzuat ve emirler çerçevesinde yürüyüp yürümediğini denetlemek ve aldığı sonuçları ve gördüğü eksiklikleri denetleme defterine kaydetmek ve takip etmek,
g) Kurum hizmetleriyle ilgili genel ihtiyaçları, öncelikleri, bir sonraki yılda yapılacak işleri belirlemek ve bu konularla ilgili tahmini gider verilerini hazırlayarak Bakanlığa sunmak,
h) Asayiş, güvenlik, sağlık ve benzeri konularda ortaya çıkan sorunlarla ilgili gecikmeksizin önlem almak, önlemlerin yetersiz kalması halinde, durumu derhal Cumhuriyet başsavcılığı aracılığıyla Bakanlığa bildirmek,
ı) Mevzuatla verilen diğer görevleri yapmak.
a) Kurum personeli üzerinde mevzuatın öngördüğü şekilde gözetim ve denetim hakkını kullanmak,
b) Kurum personeline verilen yazılı veya sözlü emirlerin yerine getirilip getirilmediğini izlemek ve denetlemek,
c) Mevzuat ve yetkili mercilerce verilen emirler çerçevesinde kurumun genel idare ve işyurduna ait hesap işlerinin yürütülmesini ve denetimini yapmak,
d) Hükümlülerin iyileştirilmesi, bilgilerinin artırılması, atölye çalışmaları, kişisel uğraşlarının düzenlenmesi ve geliştirilmesinin sağlanması bakımından mevzuat hükümlerini uygulamak ve sağlık durumlarıyla yakından ilgilenmek,
e) Kamu kurum ve kuruluşları ile bakanlıklar tarafından istenilen istatistiki bilgi ve belgelerin hazırlanmasını sağlamak ve Cumhuriyet başsavcılığına sunmak,
f) Haftada en az bir defa olmak üzere gündüzleri, on beş günde en az bir defa olmak üzere de geceleri kurumun bütün faaliyetlerini tetkik ederek, işlerin mevzuat ve emirler çerçevesinde yürüyüp yürümediğini denetlemek ve aldığı sonuçları ve gördüğü eksiklikleri denetleme defterine kaydetmek ve takip etmek,
g) Kurum hizmetleriyle ilgili genel ihtiyaçları, öncelikleri, bir sonraki yılda yapılacak işleri belirlemek ve bu konularla ilgili tahmini gider verilerini hazırlayarak Bakanlığa sunmak,
h) Asayiş, güvenlik, sağlık ve benzeri konularda ortaya çıkan sorunlarla ilgili gecikmeksizin önlem almak, önlemlerin yetersiz kalması halinde, durumu derhal Cumhuriyet başsavcılığı aracılığıyla Bakanlığa bildirmek,
ı) Mevzuatla verilen diğer görevleri yapmak.
İnfaz Koruma Memurları Çalışma Ortamı Ve Koşulları Nasıldır? 
İnfaz Koruma Memurları genelde kapalı, açık ve yarı açık ceza evlerinde, bunlara bağlı atölye ve açık alanlarda çalışırlar,Teknolojik gelişme bu mesleğin icrasını kolaylaştırmaktadır (kapalı devre TV sistemi gibi). Gardiyanlar; cezaevi üst yöneticileriyle, tutuklularla ve hükümlülerle, halktan kişilerle, meslektaşlarıyla, savcılarla, hakimlerle, avukatlarla, askerlerle, iletişim içindedir.Hükümlü ve tutuklular tarafından tehditler alabilir, fiili saldırıya uğrayabilirler. Görev bitiminde bir takım sorunlarla da karşılaşabilir. İsyanlarda rehin olma, yaralanma vb. olayları da olabilir.
İnfaz Koruma Memurları Hizmet İçi Eğitim Süreci:
İnfaz koruma memurluğu mesleğine  yeni başlayan meslek elemanının hükümlü ve tutuklularla olan ilişkilerinin daha sağlıklı olabilmesi için hizmet-içi eğitim uygulanır,Bu eğitimde; cezaevi yönetimiyle ilgili daha fazla bilgi almaları sağlanır, hükümlü ve tutuklularla daha sağlıklı,diyalog kurmaları için Türkçe’yi daha iyi kullanma yetenekleri geliştirilir. Cezaevi mevzuatı, hükümlü ve tutukluları ilgilendiren kanunlar hakkında bilgi verilir,Bu mesleğe girenlere zinde kalmaları için yakın dövüşme kuralları öğretilir. Cezaevine girmesi yasaklanan maddelerin tanıtılması için dersler verilir. (Esrar, morfin, kokain, eroin ve uyuşturucu haplar.) Meslek için önemli olan dersler; Psikoloji, Türkçe, İnfaz Hukuku, Cezaevi İdaresi, Genel Hukuk, Kriminoloji, Narkotik, Davranış Bilimleri, Ceza Mahkemeleri ,İlk Yardım ve Sağlık, Beden Eğitimi vb. dersler.
İnfaz Koruma Memurluğu Meslekte İlerleme:
Adalet Bakanlığına bağlı cezaevlerine İnfaz ve Koruma Memuru olarak giren devlet memuru görev içerisinde gösterdiği başarı durumuna göre yapılan sınavla İnfaz ve Koruma Baş Memurluğuna (baş gardiyan) yükselme imkanına sahiptir.
Yüksek okul mezunu olan İnfaz ve Koruma Memurları Adalet Bakanlığı’nın açtığı sınavlarda idare memurluğu sınavını kazanabilirlerse cezaevi 2. Müdür ve 1. Müdür kademelerine kadar yükselebilirler.
İnfaz Koruma Memuru''nun Kullandığı Araç-Gereç ve Donanımlar:
Bilgisayar,Hijyen Seti,Duyarlı Kapı,Kartuş ve Toner,El Dedektörü,Kırtasiye Malzemeleri,El Feneri,Temizlik Seti,Eldiven,Kaset,Faks,CD/DVD,Fotokopi Makinası,İlk Yardım Seti,Jop,Kalkan,Kamera sistemleri,Kapalı devre anons sistemi,Kask,Kaşe-mühür,Kayıt cihazları,Kelepçe,Koruma Elbisesi,Manyetik Kapı,Matbu defterler,Matbu formlar,Matbu tutanaklar,Monitörler,Parmak İzi Tarayıcısı (El Biyometrisi),Retina Tarayıcısı (Göz Biyometrisi),Tarayıcı,Telefon,Telsiz,Tepegöz,Tv-Radyo yayın sistemi,Üniforma,X-Ray cihazı,Yangın Söndürme Seti,Yazıcı
İnfaz Koruma Memuru İçin Gerekli Olan Bilgi Ve Beceriler:
Araç gereç ve ekipman bilgisi,Bilgisayar bilgisi,Çevre düzenleme bilgisi,Daktilo/ klavye kullanma bilgisi,Dinleme yeteneği,Ekip içinde çalışma yeteneği,Gözlem yeteneği,Hijyen bilgisi,İkna yeteneği,İletişim Yeteneği,İlk yardım bilgisi,İnsan psikolojisi bilgisi,İş yeri çalışma prosedürleri bilgisi,İşçi sağlığı ve iş güvenliği önlemleri bilgisi,Karar verme yeteneği,Kayıt tutma yeteneği,Liderlik yeteneği,Malzeme bilgisi,Mesleğe ilişkin yasal düzenlemeler bilgisi,Mesleki teknolojik gelişmelere ilişkin bilgi,Mesleki terim bilgisi,Organizasyon yeteneği,Öğrenme yeteneği,Öğretme yeteneği,Problem çözme yeteneği,Protokol bilgisi,Yakın Dövüş ve Savunma Bilgisi,Yazışma Kuralları Bilgisi
TÜRK İNFAZ TEŞKİLATI:
Kesinleşen mahkumiyet kararları, ilgili mahkemece Cumhuriyet başsavcılığına gönderilir. Buna göre cezanın infazı, Cumhuriyet savcısı tarafından izlenir ve denetlenir.
Türk İnfaz teşkilatı, Ceza ve Tevkifevleri Genel Müdürlüğü bünyesinde merkez ve taşra teşkilâtı olarak örgütlenmiştir.
Merkez Teşkilâtı; Bakanlık, Genel Müdürlük ve alt birimlerinden oluşmaktadır.
Taşra Teşkilâtı; Cumhuriyet başsavcılıkları, personel eğitim merkezleri, ceza infaz kurumları ve tutukevleri ile denetimli serbestlik ve yardım merkezlerinden oluşmaktadır.
1-Cumhuriyet Başsavcılıkları: Ceza ve Güvenlik Tedbirlerinin İnfazı Hakkındaki Kanununun 5.maddesine göre mahkeme, kesinleşen ve yerine getirilmesini onayladığı cezaya  ilişkin hükmü Cumhuriyet Başsavcılığına gönderir. Bu hükme göre cezanın infazı Cumhuriyet savcısı tarafından izlenir ve denetlenir. Mahkemelerce verilen ve kesinleşen cezalar Cumhuriyet başsavcılıklarınca infaz olunur. Ayrıca, CMK’nun 100’üncü maddesi gereğince tutuklanmasına karar verilen kişiler, Cumhuriyet başsavcılıklarının kuruma sevk emri olmadan ceza infaz kurumlarına kabul edilemezler. Bu durum tahliye kararlarının yerine getirilmesinde de söz konusudur.
Ayrıca Cumhuriyet başsavcıları, cezaevlerinde görev yapan bazı merkez ve taşra personelinin hem sicil amiri hem de disiplin amiridir. Bunun yanında adlî yargı adalet komisyonlarında üye olarak görev yapmakta ve taşra personeli olan infaz personelinin atama, görevde yükselme, görevden uzaklaştırılma, disiplin işlemleri, yargı çevresi içindeki nakilleri ve geçici görevlendirilmeleri gibi özlük işlemlerine bakmaktadır.
Bu görevlerine ilâveten ceza infaz kurumlarının diğer kuruluşlarla ilişkilerinde temsil yetkisi Cumhuriyet başsavcılıklarındadır. Ceza infaz kurumlarının yazışmaları Cumhuriyet başsavcılıkları aracılığıyla yapılmaktadır.
Bu itibarla, Cumhuriyet savcıları yargısal görevleri ayrık olmak üzere infaz hizmetlerine ilişkin görevleri bakımından Genel Müdürlüğün taşra teşkilâtını oluşturmaktadır.
2- Personel Eğitim Merkezleri: Ceza infaz sisteminin taşra teşkilâtını oluşturan diğer bir birimdir. Ülkemizde ceza infaz kurumları ve tutukevleri personeli geçmişte yeterli görülmeyen bir hizmet öncesi ve hizmet içi eğitim ile eğitilmekte iken 29.7.2002 tarihinde kabul edilen 4769 sayılı Ceza İnfaz Kurumları ve Tutukevleri Personel Eğitim Merkezleri Kanunu ile ceza infaz kurumları personelinin Türkiye’nin beş bölgesinde kurulacak olan eğitim merkezlerinde eğitimi öngörülmüştür.
Bu kurumlarda ceza infaz kurumlarında ve tutukevlerinde görev yapacak olan personelden idare memurluğu öğrencileri ile infaz ve koruma memurluğu öğrencilerinin hizmet öncesi eğitimi ile bu kurumlarda görev yapan personelin aday memurluk, hizmet içi ve görevde yükselme eğitimleri yapılacaktır. Bu kurumlardan Ankara, İstanbul ve Erzurum Eğitim Merkezleri hizmete girmiş durumda olup, diğer ikisinin kuruluş çalışmaları devam etmektedir.
Bu merkezlerde hâkim veya savcı sınıfından olan bir müdür ve bir müdür yardımcısı ile yeteri kadar idarî personel ile öğretim görevlisi bulunmaktadır. Kanun gereğince söz konusu personel eğitim merkezleri Ceza ve Tevkifevleri Genel Müdürlüğüne bağlıdır.
3- Ceza İnfaz Kurumları: Mahkemelerce usulüne uygun olarak yargılanan ve herhangi bir hürriyeti bağlayıcı cezaya mahkûm edilen kişilerin barındırıldıkları ve eğitilerek yeniden topluma kazandırıldıkları kurumlardır. Bu kurumlarda hizmetler kurum içinde örgütlenmiş bulunan çeşitli kurullar, heyetler, komisyonlar ve servisler tarafından yerine getirilir. Bunlar, İdare Kurulu, Disiplin Kurulu, Yayın Seçici Kurul, Mektup Okuma Komisyonu, İhale Komisyonu, Muayene Kabul Heyetidir.
Personel Rejimi ve Eğitimi:
Ceza ve infaz kurumlarında görev yapan idarî personel, fakülte ve yüksekokul mezunu olup, Başbakanlık tarafından yapılan Devlet Memurluğu Sınavı ile mesleğe alınırlar. Personel genellikle psikolog, sosyolog, sosyal çalışmacı, öğretmen, iktisadî ve idarî bilimler ile hukuk fakültesi mezunları arasından seçilirler. Uygulamada çok çeşitli meslekten gelen müdürler bulunmaktadır. Müdürler dışardan atanmayıp idare memuru olarak kurum içerisinde yetiştirilirler.
İnfaz ve koruma personeli yukarıda bahsi geçen sınavı kazananlar arasından mahallî komisyonlarca atanırlar. En az lise mezunu olma şartı bulunup, yüksekokul mezunları tercih edilir. Personelin eğitimi hizmet öncesi, hizmet içi ve görevde yükselme kursları ile sağlanır. Kurslarda genel hukuk, ceza hukuku, infaz hukuku, yönetim hukuku, uluslararası cezaevi standartları, sosyal ilişkiler, sosyal hizmetler, psikoloji, kriminoloji, beden eğitimi ve insan hakları gibi dersler okutulur. Ayrıca ilgili konularda seminer ve konferanslar verilir.
Kurum personeline görevi içerisinde her an başvurabileceği bir de el kitapçığı verilir. Bu kitapçıkta personelin görev, yetki ve sorumlulukları açıklanır.
Kadın ve çocuk cezaevinde çalışan personele bu konuda özel eğitim verilmelidir.
Cezaevlerinin Güvenliği:
Kapalı ceza ve infaz kurumları ile tutukevlerinde iç güvenlik Adalet Bakanlığına bağlı infaz ve koruma personeli tarafından yerine getirilir.
Bu kurumlarda dış güvenlik ise İçişleri Bakanlığına bağlı Jandarma Teşkilâtı tarafından sağlanır. Tutuklu ve hükümlülerin her türlü nakil ve sevk işlemleri ile isyan ve firar olaylarına müdahale bu birim tarafından yerine getirilir.
Açık cezaevleri ile çocuk ıslahevlerinde iç ve dış güvenlik sadece infaz ve koruma personeli tarafından sağlanır.
Cezaevlerinin Denetimi
Ceza ve infaz kurumları Adalet Bakanlığına bağlı olan ve hâkimlik ve savcılık mesleğinden gelen müfettişler ile Genel Müdürlüğe bağlı kontrolörler tarafından her yıl denetlenir (Kontrolörler hâkim ve savcılar ile adlî işlemleri denetleyemezler).
Diğer yandan cezaevleri düzenli aralıklarla ve her iki ayda bir defadan az olmamak üzere sivil toplum üyelerinden oluşan izleme kurulları tarafından denetlenir.
Aynı zamanda, her ağır ceza merkezi ile asliye ceza mahkemesi bulunan ilçelerde tutuklu ve hükümlülerin cezaevi idaresi ve infaz rejimi hakkındaki şikâyetleri ile disiplin cezalarını inceleyen infaz hâkimlikleri bulunmaktadır.
Öte yandan, ceza ve infaz kurumları TBMM İnsan Hakları İnceleme Komisyonu, Başbakanlık İnsan Hakları Başkanlığı, Adalet Bakanlığı, İnsan Haklarından Sorumlu Devlet Bakanlığı, Ceza ve Tevkifevleri Genel Müdürlüğü, Avrupa İşkenceyi Önleme Komitesi ile Birleşmiş Milletler İşkenceye Karşı Komite tarafından denetlenebilir.
Ayrıca Cumhuriyet başsavcıları da kurumları sık sık denetlemek zorundadırlar.
4- Denetimli serbestlik ve yardım merkezleri: Adlî kontrol altında tutulmasına karar verilen,  şartla tahliyesine karar verilen, cezası tecil edilen ya da hapis dışı bir ceza veya tedbire (kamu hizmetlerinde çalışma, zorunlu eğitim alma, zorunlu tedaviye tâbi tutulma, belirli meslek ve sanattan men edilme, ehliyet ve ruhsatın geri alınması, belirli yerlere gidememe vb. gibi)  mahkûm  edilen kişilerin cezalarının infaz edildiği ve bu hükümlülere psiko-sosyal hizmet ile olabilecek diğer desteğin sağlandığı, yargılanan kişiler hakkında sosyal araştırma raporlarının yazıldığı, tahliye sonrasında mahkûmlara iş ve kredi sağlandığı, ayrıca suç mağduruna yardım yapıldığı Cumhuriyet Başsavcılıklarına bağlı kurumlardır.
İnfazda temel ilke
(1) Eşitlik: Ceza ve güvenlik tedbirlerinin infazına ilişkin kurallar hükümlülerin ırk, dil, din, mezhep, milliyet, renk, cinsiyet, doğum, felsefî inanç, millî veya sosyal köken ve siyasî veya diğer fikir yahut düşünceleri ile ekonomik güçleri ve diğer toplumsal konumları yönünden ayırım yapılmaksızın ve hiçbir kimseye ayrıcalık tanınmaksızın uygulanır.
(2) İnsan hak ve onuruna saygı: Ceza ve güvenlik tedbirlerinin infazında zalimane, insanlık dışı, aşağılayıcı ve onur kırıcı davranışlarda bulunulamaz.
      İnfazda temel amaç
      Ceza ve güvenlik tedbirlerinin infazı ile ulaşılmak istenilen temel amaç, öncelikle genel ve özel önlemeyi sağlamak, bu maksatla hükümlünün yeniden suç işlemesini engelleyici etkenleri güçlendirmek, toplumu suça karşı korumak; hükümlünün, yeniden sosyalleşmesini teşvik etmek,  üretken ve kanunlara, nizamlara ve toplumsal kurallara saygılı, sorumluluk taşıyan bir yaşam biçimine uyumunu kolaylaştırmaktır.
      İnfazın koşulu ve dayanağı
      İnfazın en önemli koşulu,  mahkumiyet kararının kesinleşmesidir. Suç işlendikten sonra yapılan soruşturma ve kovuşturma neticesinde mahkemece verilen mahkumiyet kararı, ya kanun yoluna başvurulmaksızın bu konuda yasada ön görülen sürenin dolmasıyla kesinleşir. Ya da kanun yoluna başvurulması neticesi ilgili kararın onanmasıyla kesinleşir. Mahkûmiyet hükümleri, bu şekilde  kesinleşmedikçe infaz olunamaz.
Bu bilgilerden hareketle infazın dayanağı, kesinleşmiş bir mahkumiyet kararı, diğer bir anlatımla mahkumiyet ilamıdır.
Türk infaz teşkilatı
Kesinleşen mahkumiyet kararları, ilgili mahkemece Cumhuriyet başsavcılığına gönderilir. Buna göre cezanın infazı, Cumhuriyet savcısı tarafından izlenir ve denetlenir.
Türk İnfaz teşkilatı, Ceza ve Tevkifevleri Genel Müdürlüğü bünyesinde merkez ve taşra teşkilâtı olarak örgütlenmiştir.
            Merkez Teşkilâtı; Bakanlık, Genel Müdürlük ve alt birimlerinden oluşmaktadır.
            Taşra Teşkilâtı; Cumhuriyet başsavcılıkları, personel eğitim merkezleri, ceza infaz kurumları ve tutukevleri ile denetimli serbestlik ve yardım merkezlerinden oluşmaktadır.
İNFAZ HUKUKUNUN TEMEL KAVRAMLARI
            Suç:
            Suç, hukuk terminolojisine göre kendisine yaptırım olarak ceza konulmuş eylemdir. Başka bir tanıma göre kanun ile korunan kuralların bozulmasıdır.
Suçun dört genel unsuru bulunmaktadır:
1-Kanunilik unsuru: İşlenen fiilin kanundaki suç tanımına uygun olması, kanunun söz konusu eylemi doğrudan suç olarak tanımlamış olması gerekir.
2-Maddi unsur: Bir fiil bulunmalıdır.
3-Hukuka aykırılık unsuru: Fiil hukuk kurallarına aykırı olmalıdır.
4-Manevi Unsur: Fiil bilerek ve istenerek işlenmelidir.
Suçun maddi konusu; suçtan etkilenen insan veya şeydir.
Suçun hukuki konusu ise bir ceza normu ile korunan diğer bir anlatımla suçla ihlal edilen hak ve menfaattir.
            Ceza:
Hukuk terminolojisinde ceza; kanunlarla öngörülen, topluma ve bireye belli ölçüde zarar veren fiillerin karşılığı olarak suç failine ızdırap çektirmek amacıyla, bazı mahrumiyetlere tabi tutan, kazai bir kararla ve failin kusurluluğu ile orantılı ve onun şahsına uygun olarak hükmedilen korkutucu bir yaptırım olarak tanımlanabilir.
TCK.nun 45.maddesinde cezalar; hürriyeti bağlayıcı cezalar ve adli para cezaları olarak ikiye ayrılmıştır.
            1-Hürriyeti Bağlayıcı Cezalar:
Hürriyeti bağlayıcı cezalar, kanunda şu şekilde tasnife tabi tutulmuştur.
a) Ağırlaştırılmış müebbet hapis cezası
b) Müebbet hapis cezası
c) Süreli hapis cezası
a) Ağırlaştırmış müebbet hapis cezası; hükümlünün hayatı boyunca devam eder ve sıkı güvenlik rejimine göre çektirilir. Bu cezaya hükümlü olanlar, hiçbir şekilde ceza infaz kurumunun dışında çalıştırılmamakta ve kendilerine izin verilmemekte, kurum iç yönetmeliğinde belirtilenlerin dışında herhangi bir spor faaliyetine katılamamakta ayrıca hiçbir şekilde cezanın infazına ara verilmemektedir.
b)Müebbet hapis cezası; hükümlünün hayatı boyunca devam eder. Bu cezada sıkı güvenlik rejimi uygulanmamaktadır.
c)Süreli hapis cezası; kanunda aksi belirtilmeyen hallerde bir aydan az, yirmi yıldan fazla olamaz. Hükmedilen bir yıl ve daha az hapis cezası, kısa süreli hapis cezasıdır. Kısa süreli hapis cezaları, belli kriterler esas alınarak TCK.nun 50.maddesinde sayılan alternatif yaptırımlara çevrilebilmektedir.
Kısa süreli hapis cezası, suçlunun kişiliğine, sosyal ve ekonomik durumuna, yargılama sürecinde duyduğu pişmanlığa ve suçun işlenmesindeki özelliklere göre;
a)      Adlî para cezasına,
b)      Mağdurun veya kamunun uğradığı zararın aynen iade, suçtan önceki hâle getirme veya tazmin suretiyle, tamamen giderilmesine,
c)      En az iki yıl süreyle, bir meslek veya sanat edinmeyi sağlamak amacıyla, gerektiğinde barınma imkânı da bulunan bir eğitim kurumuna devam etmeye,
d)      Mahkûm olunan cezanın yarısından bir katına kadar süreyle, belirli yerlere gitmekten veya belirli etkinlikleri yapmaktan yasaklanmaya,
e)      Sağladığı hak ve yetkiler kötüye kullanılmak suretiyle veya gerektirdiği dikkat ve özen yükümlülüğüne aykırı davranılarak suç işlenmiş olması durumunda; mahkûm olunan cezanın yarısından bir katına kadar süreyle, ilgili ehliyet ve ruhsat belgelerinin geri alınmasına, belli bir meslek ve sanatı yapmaktan yasaklanmaya,
f)        Mahkûm olunan cezanın yarısından bir katına kadar süreyle ve gönüllü olmak koşuluyla kamuya yararlı bir işte çalıştırılmaya,
Çevrilebilir.
Suç tanımında hapis cezası ile adlî para cezasının seçenek olarak öngörüldüğü hâllerde, hapis cezasına hükmedilmişse; bu ceza artık adlî para cezasına çevrilmez.
Daha önce hapis cezasına mahkûm edilmemiş olmak koşuluyla, mahkûm olunan otuz gün ve daha az süreli hapis cezası ile fiili işlediği tarihte onsekiz yaşını doldurmamış veya altmışbeş yaşını bitirmiş bulunanların mahkûm edildiği bir yıl veya daha az süreli hapis cezası, birinci fıkrada yazılı seçenek yaptırımlardan birine çevrilir.
Taksirli suçlardan dolayı hükmolunan hapis cezası uzun süreli de olsa; bu ceza, diğer koşulların varlığı hâlinde, birinci fıkranın (a) bendine göre adlî para cezasına çevrilebilir. Ancak, bu hüküm, bilinçli taksir hâlinde uygulanmaz.
Uygulamada asıl mahkûmiyet, bu madde hükümlerine göre çevrilen adlî para cezası veya tedbirdir.
Hüküm kesinleştikten sonra Cumhuriyet savcılığınca yapılan tebligata rağmen otuz gün içinde seçenek yaptırımın gereklerinin yerine getirilmesine başlanmaması veya başlanıp da devam edilmemesi hâlinde, hükmü veren mahkeme kısa süreli hapis cezasının tamamen veya kısmen infazına karar verir ve bu karar derhâl infaz edilir. Bu durumda, beşinci fıkra hükmü uygulanmaz. Yani asıl mahkûmiyet, bu madde hükümlerine göre çevrilen adlî para cezası veya tedbirdir değil, tamamen ya da kısmen infazına karar verilen hürriyeti bağlayıcı cezadır.
Hükmedilen seçenek tedbirin hükümlünün elinde olmayan nedenlerle yerine getirilememesi durumunda, hükmü veren mahkemece tedbir değiştirilir.
2.Adli Para Cezası:
            Adli para cezası, beş günden az, kanunda aksi belirtilmeyen hallerde yediyüzotuz günden fazla olmamak üzere belirlenen tam gün sayısının, bir gün karşılığı olarak takdir edilen miktar ile çarpılması suretiyle hesaplanan meblağın, hükümlü tarafından Devlet Hazinesine ödenmesinden ibarettir.
En az yirmi ve en fazla yüz Türk Lirası olan bir gün karşılığı adlî para cezasının miktarı, kişinin ekonomik ve diğer şahsî hâlleri göz önünde bulundurularak takdir edilir.
Kararda, adlî para cezasının belirlenmesinde esas alınan tam gün sayısı ile bir gün karşılığı olarak takdir edilen miktar ayrı ayrı gösterilir.
Hâkim, ekonomik ve şahsî hâllerini göz önünde bulundurarak, kişiye adlî para cezasını ödemesi için hükmün kesinleşme tarihinden itibaren bir yıldan fazla olmamak üzere mehil verebileceği gibi, bu cezanın belirli taksitler hâlinde ödenmesine de karar verebilir. Taksit süresi iki yılı geçemez ve taksit miktarı dörtten az olamaz. Kararda, taksitlerden birinin zamanında ödenmemesi hâlinde geri kalan kısmın tamamının tahsil edileceği ve ödenmeyen adlî para cezasının hapse çevrileceği belirtilir.
Ceza ve Güvenlik Tedbirlerinin İnfazı Hakkındaki Kanunda Adli Para Cezası şu şekilde düzenlenmiştir:
      MADDE 106.-
(1) Adlî para cezası, Türk Ceza Kanununun 52 nci maddesinin birinci fıkrasında belirtilen usule göre tayin olunacak bir miktar paranın Devlet Hazinesine ödenmesinden ibarettir.
(2) Adlî para cezasını içeren  ilâm Cumhuriyet Başsavcılığına verilir. Cumhuriyet savcısı otuz gün içinde adlî para cezasının ödenmesi için hükümlüye 20 nci maddenin üçüncü fıkrası uyarınca bir ödeme emri tebliğ eder.
(3) Hükümlü, tebliğ olunan ödeme emri üzerine belli süre içinde adlî para cezasını ödemezse, Cumhuriyet savcısının kararı ile ödenmeyen kısma karşılık gelen gün miktarınca hapsedilir.
(4) Çocuklar hakkında hükmedilen; adli para cezası ile hapis cezasından çevrilen adli para cezasının ödenmemesi halinde, bu cezalar hapse çevrilemez. Bu takdirde onbirinci fıkra hükmü uygulanır.
(5) Adlî para cezasının hapse çevrileceği mahkeme ilâmında yazılı olmasa bile üçüncü fıkra hükmü Cumhuriyet Başsavcılığınca uygulanır.
(6) Hükümde, adlî para cezası takside bağlanmamış ise, bir aylık süre içinde adlî para cezasının üçte birini ödeyen hükümlünün isteği üzerine geri kalan kısmının birer ay ara ile iki eşit taksitte ödenmesine izin verilir. İlk taksidin süresinde ödenmemesi hâlinde, verilen ikinci takside ilişkin izin hükümsüz kalır.
(7) Adlî para cezası yerine çektirilen hapis süresi  üç yılı geçemez. Birden fazla hükümle adlî para cezalarına mahkûmiyet hâlinde bu süre beş yılı geçemez.
(8) Hükümlü, hapis yattığı günlerin dışındaki günlere karşılık gelen parayı öderse hapisten çıkartılır.
(9) Türk Ceza Kanununun 50 nci maddesinin birinci fıkrasının (a) bendi saklı kalmak üzere, adlî para cezasından çevrilen hapsin infazı ertelenemez ve bunun infazında koşullu salıverilme hükümleri uygulanamaz. Hapse çevrilmiş olmasına rağmen hak yoksunlukları bakımından esas alınacak olan adlî para cezasıdır.
(10) Türk Ceza Kanununun 50 nci maddesinin birinci fıkrasının (a) bendine göre kısa süreli hapis cezasından çevrilen adlî para cezalarının infazında, aynı maddenin altıncı ve yedinci fıkraları hükümleri saklıdır.
(11) İnfaz edilen hapsin süresi, adlî para cezasını tamamıyla karşılamamış olursa, geri kalan adlî para cezasının tahsili için ilâm, Cumhuriyet Başsavcılığınca mahallin en büyük mal memuruna verilir. Bu makamlarca 6183 sayılı Amme Alacaklarının Tahsil Usulü Hakkında Kanuna göre kalan adlî para cezası tahsil edilir.
             Tutuklu:
Hakkında tutulama kararı verilen kişiye tutuklu denir. Peki tutuklama nedir?
Tutuklama, Anayasada ve kanunda belirtilen koşullardan birinin varlığı halinde, suçluluğu hakkında kuvvetli belirti bulunan bir kişinin, hükümden önce, ihtiyari ve geçici bir tedbir olarak, yargılamanın güvenli yürümesine hizmet amacıyla bir tutukevine konulmak üzere hakimin kararıyla hürriyetinden mahrum edilmesidir. Kısa bir ifadeyle, suç işlediğine dair hakkında kuvvetli delil bulunan sanığın özgürlüğünün hakim kararıyla sınırlanmasıdır.
Tutuklama, ceza değil bir tedbirdir.
      Tutuklama nedenleri
Ceza Muhakemesi Kanununda tutuklama nedenleri şu şekilde sayılmıştır.
      MADDE 100. –
(1) Kuvvetli suç şüphesinin varlığını gösteren olguların ve bir tutuklama nedeninin bulunması halinde, şüpheli veya sanık hakkında tutuklama kararı verilebilir. İşin önemi, verilmesi beklenen ceza veya güvenlik tedbiri ile ölçülü olmaması halinde, tutuklama kararı verilemez.
(2) Aşağıdaki hallerde bir tutuklama nedeni var sayılabilir:
a) Şüpheli veya sanığın kaçması, saklanması veya kaçacağı şüphesini uyandıran somut olgular varsa.
b) Şüpheli veya sanığın davranışları;
1. Delilleri yok etme, gizleme veya değiştirme,
2. Tanık, mağdur veya başkaları üzerinde baskı yapılması girişiminde bulunma,
Hususlarında kuvvetli şüphe oluşturuyorsa.
(3) Aşağıdaki suçların işlendiği hususunda kuvvetli şüphe sebeplerinin varlığı halinde, tutuklama nedeni var sayılabilir:
a) 26.9.2004 tarihli ve 5237 sayılı Türk Ceza Kanununda yer alan;
1. Soykırım ve insanlığa karşı suçlar (madde 76, 77, 78),
2. Kasten öldürme (madde 81, 82, 83),
3. İşkence (madde 94, 95)
4. Cinsel saldırı (birinci fıkra hariç, madde 102),
5. Çocukların cinsel istismarı (madde 103),
6. Uyuşturucu veya uyarıcı madde imal ve ticareti (madde 188),
7. Suç işlemek amacıyla örgüt kurma (iki, yedi ve sekizinci fıkralar hariç, madde 220),
8. Devletin Güvenliğine Karşı Suçlar (madde 302, 303, 304, 307, 308),
9. Anayasal Düzene ve Bu Düzenin İşleyişine Karşı Suçlar (madde 309, 310, 311, 312, 313, 314, 315),
b) 10.7.1953 tarihli ve 6136 sayılı Ateşli Silahlar ve Bıçaklar ile Diğer Aletler Hakkında Kanunda tanımlanan silah kaçakçılığı (madde 12) suçları.
c) 18.6.1999 tarihli ve 4389 sayılı Bankalar Kanununun 22 nci maddesinin (3) ve (4) numaralı fıkralarında tanımlanan zimmet suçu.
d) 10.7.2003 tarihli ve 4926 sayılı Kaçakçılıkla Mücadele Kanununda tanımlanan ve hapis cezasını gerektiren suçlar.
e) 21.7.1983 tarihli ve 2863 sayılı Kültür ve Tabiat Varlıklarını Koruma Kanununun 68 ve 74 üncü maddelerinde tanımlanan suçlar.
f) 31.8.1956 tarihli ve 6831 sayılı Orman Kanununun 110 uncu maddesinin dört ve beşinci fıkralarında tanımlanan kasten orman yakma suçları.
(4) Sadece adlî para cezasını gerektiren veya hapis cezasının üst sınırı bir yıldan fazla olmayan suçlarda tutuklama kararı verilemez.
            Hükümlü:
Yapılan soruşturma ve yargılama sonunda hakimin uyuşmazlık konusunu esastan halleden ve yargılamayı sona erdiren kararına hüküm, böyle bir mahkumiyet hükmü alan kimseye de hükümlü denir. Kısaca hakkında kesinleşmiş ceza mahkumiyeti bulunan kimsedir.
            Hükümözlü (Hükmen Tutuklu)
Yapılan soruşturma ve yargılama neticesi hakkında mahkumiyet kararı verilen, ancak kararla ilgili temyiz süresi dolmayan veya kararı temyiz edilmekle birlikte onaylanmayan tutuklulara hükümözlü ya da hükmen tutuklu denir.
Sanıklar hakkında verilen mahkumiyet kararları kesinleşmedikçe infaz edilemeyeceği için hükmen tutuklular hükümlü statüsünde sayılmazlar. Bunun doğal sonucu olarak koşullu salıverme hükümlerinden yararlanamazlar. Hükümlülerle aynı yerde barındırılmamaktadırlar.
            Tehlikeli Hükümlü
Tehlikeli hükümlülerin tanımı Avrupa Konseyi Bakanlar Komitesinin R(82)17 sayılı Tavsiye Kararında yapılmıştır. Buna göre; “İşlediği suçun nitelik ve icra şekli göz önüne alındığında; toplum için ciddi bir tehlike oluşturan ve cezaevi güvenlik ve nizamını ihlal edebileceği yönünde kuvvetli delil bulunan hükümlüdür.”
Tehlikelilik kavramı, kişiye, işlenen suça, içinde yaşanılan toplumun yaşam kriterlerine göre değişiklik gösterebilecektir. Ancak uygulamada, cezaevindeki yaşama uyum göstermeyenler, firar etme riski bulunanlar, personele ve hükümlülere karşı saldırganlık gösterenler, psikopatlar, intihar etme eğilimi olanlar genellikle tehlikeli suçlu özellikleri taşıyan insanlardır.
Yüksek ölçüde kaçma tehlikesi ortaya koyan veya cebir kullanacağından korkulan veya intihar etme riski gösteren bir kişi “Tehlikeli” suçlu olarak tanımlanmaktadır.
Ceza ve Güvenlik Tedbirlerinin İnfazı Hakkındaki Kanunun 9.Maddesinin 3. Fıkrasına göre “Eylem ve tutumları nedeniyle tehlikeli halde bulunanlar” yüksek güvenlikli kapalı ceza infaz kurumuna gönderilirler.
            V-İLAMIN İNCELENMESİ VE İNFAZ İŞLEMLERİ
             İnfaz, sözlükteki anlamıyla yerine getirme demektir. Hukuk terminolojisinde infaz, mahkeme kararının yerine getirilmesini ifade etmektedir. İnfaz edilecek mahkeme kararına ilam denmektedir.
            İlamın incelenmesinde dikkat edilecek konular
 1)      İlamın kesinleşme şerhinin bulunup bulunmadığı, hangi hükümlü için ve hangi cezanın infazı için ilamın Cumhuriyet başsavcılığına verildiği kaydı kontrol edilmelidir.Kesinleşmemiş ilamlar infaz edilmemelidir. Mahkeme ilamında bir sanık için birden fazla cezaya veya birden fazla hükümlü için ayrı ayrı cezalara hükmedilmiş olabilir. Bu nedenle kararın kesinleşme şerhinde hükmün kesinleştiği tarih ile hangi sanık için hangi cezanın infaza verildiği açık bir şekilde yazılmış olmalıdır.
2)      TCK. 51. Maddesi gereğince cezanın ertelenip ertelenmediği kontrol edilmelidir.
3)      TCK. 50. maddesinde geçen 30 gün ve daha az hapis cezası ile daha önce hapis cezasına mahkum edilmemiş olmak koşuluyla fiili işlediği tarihte on sekiz yaşını doldurmamış veya altmış beş yaşını bitirmiş bulunanların mahkum edildiği bir yıl veya daha az süreli hapis cezasının aynı maddenin birinci fıkrasında yazılı ceza ya da tedbirlerden birine çevrilip çevrilmediği incelenmelidir.
4)      Hükümde TCK.nun 66 ve 73. maddeleri gereğince dava zamanaşımı ve şikayetten vazgeçme şeklinde bir kayıt bulunup bulunmadığı kontrol edilmelidir. İlamda bu maddeler uygulanmış ise evrak ilamat defterine kaydedilmemelidir.
5)      Hükümlünün ilamda yazılı suçtan tutuklu kalıp kalmadığı ve bu suçtan tutuklu kalmış ise tutuklulukta geçirdiği sürenin şartla tahliye süresini karşılayıp karşılamadığı kontrol edilmelidir. Eğer karşılıyor ise mahkemesinden şartla tahliye kararı alınmalı ve ilamat defterindeki kayıt kapatılarak mahkemesine gönderilmelidir.
6)      İlamın ceza zamanaşımına uğrayıp uğramadığı kontrol edilmelidir.
7)      Hükümde hata olup olmadığı kontrol edilmelidir. Örneğin adli para cezası ya da hürriyeti bağlayıcı cezanın yanlış hesaplanması durumunda evrakın ilamat defterine kaydı yapılmamalı ve kanun yoluna başvurulmalıdır.
8)      Fiilin suç olmaktan çıkartılıp çıkartılmadığı, affa uğrayıp uğramadığı incelenmelidir.
            HAPİS CEZALARININ İNFAZI
       Hapis cezalarının infazında gözetilecek ilkeler
Hapis cezalarının infaz rejimi, aşağıda gösterilen temel ilkelere dayalı olarak düzenlenir:
a-      Hükümlüler  ceza  infaz  kurumlarında  güvenli  bir  biçimde  ve kaçmalarını önleyecek tedbirler alınarak düzen, güvenlik ve disiplin çerçevesinde  tutulurlar.
b-     Ceza infaz kurumlarında hükümlülerin düzenli bir yaşam sürdürmeleri sağlanır. Hürriyeti bağlayıcı cezanın zorunlu kıldığı hürriyetten yoksunluk, insan onuruna saygının  korunmasını sağlayan maddî ve manevî koşullar altında çektirilir. Hükümlülerin, Anayasada yer alan diğer hakları, infazın temel amaçları saklı kalmak üzere, bu Kanunda öngörülen kurallar uyarınca kısıtlanabilir.
c-      Cezanın infazında hükümlünün iyileştirilmesi hususunda mümkün olan araç ve olanaklar kullanılır. Hükümlünün  kanun, tüzük ve yönetmeliklerle tanınmış haklarının dokunulmazlığını sağlamak üzere cezanın infazında ve iyileştirme çabalarında kanunîlik ve hukuka uygunluk ilkeleri esas alınır.
d-     İyileştirmeye gereksinimleri olmadığı saptanan hükümlülere ilişkin infaz rejiminde, bu hükümlülerin kişilikleriyle orantılı bireyselleştirilmiş programlara yer verilmesine özen gösterilir  ve bu hususlar yönetmeliklerde düzenlenir.
e-      Cezanın infazında adalet esaslarına uygun hareket edilir. Bu maksatla ceza infaz kurumları kanun, tüzük ve yönetmeliklerin verdiği yetkilere dayanarak nitelikli elemanlarca denetlenir.
f-        Ceza infaz kurumlarında hükümlülerin yaşam hakları ile beden ve ruh bütünlüklerini korumak üzere her türlü koruyucu tedbirin alınması zorunludur.
g-      Hükümlünün infazın amacına uygun olarak kanun, tüzük ve yönetmeliklerin belirttiği hükümlere uyması zorunludur.
h-      Kanunlarda gösterilen tutum, davranış ve eylemler ile kurum düzenini ihlâl edenler hakkında Kanunda belirtilen disiplin cezaları uygulanır. Cezalara, Kanunda belirtilen merciler, sürelerine uygun olarak hükmederler. Cezalara karşı savunma ve itirazlar da Kanunun gösterdiği mercilere yapılır.
      İyileştirmede başarı ölçütü
(1) Hapis cezalarının infazında hükümlülerin iyileştirilmeleri amacını güden programların başarısı, elde ettikleri yeni tutum ve becerilerle orantılı olarak ölçülür. Bunun için iyileştirme çabalarına yönelik olarak hükümlünün istekli bulunması teşvik edilir.
(2) Hapis cezasının, kendisinde var olan zararlı etki yapıcı niteliğini mümkün olduğu ölçüde azaltacak biçimde düzenlenecek programlar, usûller, araçlar ve zihniyet doğrultusunda yerine getirilmesi esasına uyulur. İyileştirme araçları hükümlünün sağlığını ve kişiliğine olan saygısını korumasını sağlayacak usûl ve esaslara göre uygulanır.
            Hapis Cezalarının İnfazı  işlemleri
             Kararı veren mahkeme, hükmün kesinleşmesini müteakip bir hafta içinde aynı yerde bulunan Cumhuriyet Başsavcılığına kararı göndermelidir.
            Kararı veren mahkemenin yanında bulunan Cumhuriyet Başsavcılığının yargı çevresinde oturan hükümlüye ait ilamın infazı İşlemi:
 1-      Hükümlü ilamdaki suç nedeniyle tutuklu ya da başka bir suç nedeniyle aynı yerde hükümlü değilse:
Hükümlü hakkında kaçacağı ya da kaçacağına dair şüphenin bulunmaması ve üç yıldan az hapis cezasının bulunması halinde; hükümlünün mahkeme kararında belirtilen adresine çağrı kağıdı gönderilmelidir. Çağrı kağıdı üzerine gelen ve CGTİHK nun 17. maddesi uyarınca erteleme talebinde bulunmayan hükümlü hakkında müddetname tanzim edilerek cezaevine gönderilmelidir.
Şu hallerde de hükümlü hakkında yakalama müzekkeresi çıkartılmalıdır:
a)      Cezanın 3 yıldan fazla hapis olması. Burada dikkat edilmesi gereken konu, mahkeme hükmünde mahsubu öngörülen tutululukta ve nezarette geçen sürelerin ilam geldiğinde hesaplanarak bakiye ceza üzerinden ödeme emri, çağrı kağıdı veya yakalama müzekkeresi çıkartılması gerektiğidir.
b)      Hükümlünün kaçması ya da kaçacağı yolunda şüpheler bulunması,
c)      Usulüne uygun çağrı kağıdına rağmen 10 gün içinde Cumhuriyet başsavcılığına başvurmamış olması,
d)      Cezasının infazı ertelenmiş olup da erteleme süresi sonunda hükümlünün Cumhuriyet başsavcılığına başvurmamış olması.
Yakalama müzekkeresi doğrultusunda yakalanan hükümlüyle ilgili müddetname düzenlenerek cezaevine gönderilir.
 2-      Hükümlü, infaz edilecek ilam nedeniyle cezaevinde tutuklu olarak bulunuyorsa; müddetname düzenlenerek ilam evrakı cezaevine gönderilmelidir. Cezaevinde müddetnamenin bir sureti hükümlüye tebliğ edilmelidir. Bu durumda kişi tutuklu statüsünden çıkmış hükümlü statüsüne geçmiştir. Bu nedenle kişinin tutuklu defterinde bulunan kaydı kapatılmalı, hükümlü defterine kaydı yapılmalıdır.
 
 3-      Hükümlü, başka bir suçtan dolayı cezaevinde hükümlü olarak bulunuyorsa; görevli mahkemesinden alınacak toplama kararıyla cezalar toplanıp yeniden müddetname düzenlenerek buna göre infaz işlemi yapılmalıdır. Bu hususta hüküm vermek yetkisi en fazla cezaya hükmetmiş olan mahkemeye, bu durumda birden çok mahkeme yetkili ise en son hükmü vermiş olan mahkemeye; hükümlerden biri doğrudan doğruya bölge adliye mahkemesi tarafından verilmiş ise bölge adliye mahkemesine, Yargıtay tarafından verilmiş ise Yargıtay’a aittir. Toplanan bütün cezalara ait ilamlar, müddetnamenin altına not olarak yazılmalıdır.
 
 4-      Hükümlünün, başka bir suçtan dolayı cezaevinde tutuklu bulunması halinde izlenecek yöntem:
Kural olarak ilamların infazı, tutuklama kararlarının infazından önce gelir. Bu durumda ilamın infazına başlanıp tutukluluk hali durdurulur. İleride yanlışlıklara sebebiyet verilmemesi için Cezaevi müdürlüğünce ilgili mahkemeye durum bildirilmelidir.
Yukarıdaki olasılıklardan birine göre cezaevine alınan hükümlü için Cumhuriyet Savcısınca cezaevi müdürlüğüne aşağıdaki yazı yazılır:
1-     Müddetnameye göre cezanın infazı
2-     Yiyecek bordrosu yapılarak hükümlüye tebliği: (Altı aydan fazla hürriyeti bağlayıcı cezaya mahkum edilenler için altı ayda bir,altı aydan az hürriyeti bağlayıcı cezaya mahkum edilenler için salıverilecekleri tarihten bir hafta önce düzenlenmeli)
3-     Hükümlünün askerlikle ilişkisi var ise tahliyesinde serbest bırakılmayarak askerlik şubesi başkanlığına teslim edilmek üzere jandarma komutanlığına teslimi,
4-     Bir yıl ya da daha fazla hürriyeti bağlayıcı cezaya mahkum edilen reşit hükümlüler için vasi atanması yolunda yazı yazılması istenir. Vasi atamada yetkili merci hükümlünün cezaevine alınmadan önceki en son ikametgahı sulh hukuk mahkemesidir. Vasi atanması için Cezaevi müdürlüğü, iki ay içinde bu yer mahkemesine Cumhuriyet savcılığı aracılığı ile yazı yazmalı ve yetkili sulh hukuk mahkemesince resen araştırma yapılarak vasi atanmalıdır.
            Hükümlünün kararı veren mahkemenin yanında bulunan Cumhuriyet Başsavcılığının yargı çevresi dışında oturması halinde hürriyeti bağlayıcı cezanın infazı İşlemi:
             İlam oturulan yerin yargı çevresinde bulunan C.Savcılığına postayla ve mutlaka iadeli taahhütlü mektup ile gönderilmelidir. İnfaz işlemleri bu Cumhuriyet başsavcılığınca yürütülür.
İlamı alan Cumhuriyet Savcılığı, yukarıda açıklandığı gibi ilam üzerinde gerekli incelemeleri yaptıktan sonra ilamı, ilamat defterine kaydetmeli ve ilamat numarasını ilamı gönderen Cumhuriyet başsavcılığına bildirmelidir. Ayrıca ilamın akıbeti hakkında düzenli aralıklarla ilamı gönderen Cumhuriyet başsavcılığına bilgi vermelidir.  
            Mükerrirlere Özgü İnfaz Rejimi:
             Tekerrür: Daha önce işlenen suça ilişkin mahkumiyet kararının kesinleşmesinden sonra tekerrüre esas yeni bir suç işlenmesidir.
Sonradan işlenen bir suç nedeniyle tekerrür hükümlerinin uygulanabilmesi için bu suçun; önceden işlenen bir suçtan dolayı beş yıldan fazla süreyle hapis cezasına mahkumiyet halinde cezanın infaz edildiği tarihten itibaren beş yıl içinde işlenmesi; önceden işlenen bir suçla ilgili beş yıl ya da daha az süreli hapis ya da adli para cezasına mahkumiyet halinde ise bu cezanın infaz edildiği tarihten itibaren üç yıl içinde sonraki suçun işlenmesi gerekir.
Ceza Ve Güvenlik Tedbirlerinin İnfazına Dair Kanunun 108. maddesinde mükerrirlere özgü infaz rejimi ve denetimli serbestlik tedbiri şu şekilde düzenlenmiştir.
Tekerrür hâlinde işlenen suçtan dolayı mahkûm olunan;
a) Ağırlaştırılmış müebbet hapis cezasının otuzdokuz yılının,
b) Müebbet hapis cezasının otuzüç yılının,
c) Süreli hapis cezasının dörtte üçünün,
İnfaz kurumunda iyi hâlli olarak çekilmesi durumunda, koşullu salıverilmeden yararlanılabilir.
Tekerrür nedeniyle koşullu salıverme süresine eklenecek miktar, tekerrüre esas alınan cezanın en ağırından fazla olamaz.
İkinci defa tekerrür hükümlerinin uygulanması durumunda, hükümlü koşullu salıverilmez.
Hâkim, mükerrir hakkında cezanın infazının tamamlanmasından sonra başlamak ve bir yıldan az olmamak üzere denetim süresi belirler.
Tekerrür dolayısıyla belirlenen denetim süresinde, koşullu salıverilmeye ilişkin hükümler uygulanır.
Hâkim, mükerrir hakkında denetim süresinin uzatılmasına karar verebilir. Denetim süresi en fazla beş yıla kadar uzatılabilir.
Görüldüğü üzere, 765 sayılı Türk Ceza Kanunundan farklı olarak  5237 sayılı Türk Ceza Kanununda verilen cezaların tekerrür nedeniyle artırılması düzenlenmemiş ve bu husus infaz aşamasından dikkate alınarak ayrı bir koşullu salıverme hâli düzenlenmiştir.
Koşullu Salıverme:
      Koşullu salıverme, hakkında hükmedilen hapis cezasının bir kısmını cezaevinde iyi halli olarak geçiren hükümlünün, yasada ön görülen diğer koşulların da varlığı halinde bihakkın tahliye tarihinden önce salıverilmesidir.
Hükümlünün koşullu salıverilmeden faydalanabilmesi için,  ceza infaz kurumlarının düzen ve güvenliği amacıyla konulmuş kurallara içtenlikle uyması, haklarını iyi niyetle kullanması, yükümlülüklerini eksiksiz yerine getirmesi ve uygulanan iyileştirme programlarına göre de toplumla bütünleşmeye hazır olduğunun disiplin kurulunun görüşü alınarak idare kurulunca saptanmış bulunması gerekmektedir. (md. 89).


1987′den 2013′e Anayasa değişiklikleri
12 Eylül 1982. Türkiye’de askeri darbeyle sivil otorite görevden uzaklaştırıldı. Yerine silahlı güce dayanan otorite geldi. Koşullar neydi, nasıl oluştu? Hep tartışıldı. Bu tartışma daha süreceğe benziyor.
Her darbe yönetiminde olduğu gibi 12 Eylül yönetimi de kendi hukuksal sistemini oluşturdu. Yapılan 1982 Anayasası, 7 Kasım 1982 tarihindeki halkoylamasında yüzde 91.17 ”Evet” oyuyla kabul edildi. Bu orana nasıl ulaşıldığı da tartışılagelen bir durum. Sonunda askeri yönetim tarafından yap(tır)ılan anayasa 9 Kasım 1982′de yürürlüğe girdi. Anayasa toplam 177 madde ve 16 geçici maddeden oluşuyordu. Eleştirilen çok yönü vardı, ancak maddeler kendi kendi bütünlüğü içinde ve öngörülen yapısal oluşum içinde düzenlenmişti.

1982 Anayasal sisteminin daha beşinci yılında ilk değişiklik gündeme geldi. Aradan geçen 25 yılda,  1982 Anayasası’nın 106 maddesi ve 4 geçici maddesi ile bir kez de başlangıç metni değiştirildi. Eklenen üç geçici maddeden ikisi daha sonra metinden çıkarıldı. Bu değişikliklerin biri Anayasa Mahkemesi’nce iptal edildi. Yapılan değişiklikler, 1982 Anayasası’nın yüzde 60′nın yeniden düzenlenmesi niteliğindeydi.
Türkiye’de bugün yeni bir anayasa metni hazırlanıyor. Bu amaçla kurulan uzlaşma komisyonu, ilk değişikliğin 25. yıldönünde yeni bir anayasal metin ortaya koyma çabasında. Bu çabanın sonucu, sivillerin toplumsal uzlaşma kültürünün nereye kadar götürülebileceğinin de bir örneği olacak. Bugünkü çalışmaların sonunda ”toplumsal uzlaşı” mı ortaya konulacak, yoksa yeni bir ”anayasa tartşması” mı başlayacak, bunu zaman gösterecek.
1982 Anayasası’nda farklı iktidarlar döneminde yapılan değişiklikler şöyle sıralanabilir:
Siyasi yasaklar kalktı 
1982 Anayasası’ndaki ilk değişiklik anayasanın kabulünden 5 yıl sonra yapıldı.14 Mayıs 1984 tarihinde TBMM’de kabul edilen bu değişiklik 17 Mayıs 1987′de Resmi Gazete’de yayımlandı. İktidarda ANAP vardı ve Başbakan Turgut Özal’dı.
Bu düzenlemeyle Anayasa’nın 67, 75. ve 175. maddeleri yeniden düzenleniyor, Geçici 4. madde ise yürürlükten kaldırılıyordu. 67. maddenin değiştirilmesiyle  seçmen olma yaşı 21′den 19′a indirildi; 75. madde yeniden düzenlenerek milletvekili sayısı 400′den 450′ye yükseltildi.
12 Eylül öncesi siyasi partilerin ve liderlerine siyaset yasağı getiren Geçici 4. madde, bu konuda yapılan halkoylamasıyla yürürlükten kaldırıldı. Bu, 12 Eylül yasakçı yaklaşımına yönelik bir tavır olarak da yorumlanıyordu. Böylece, Süleyman Demirel, Bülent Ecevit, Necmettin Erbakan ve Alparslan Türkeş gibi liderlerin de aralarında bulunduğu kişiler ve siyasi partilerine yönelik siyaset yasağı sona erdi.
Radyo ve TV yayıncılığına serbestlik 
Anayasa’daki ikinci değişiklik 8 Temmuz 1993 tarihinde yapıldı.  İktidarda bu kez DYP-SHP koalisyon hükümeti vardı ve Başbakanlık koltuğunda Tansu Çiller oturuyordu.
Radyo ve televizyon yayıncılığıyla ilgili 133. maddesi yeniden düzenlendi. Böylece, radyo ve televizyon istasyonları kurmak ve işletmek, yasal düzenlemelerle oluşturulacak şartlar çerçevesinde serbest hale getirildi.

Milletvekili sayısı arttı 
Anayasa’daki 23 Temmuz 1995 tarihinde yapılan üçüncü değişiklik geniş kapsamlıydı. Anayasanın başlangıç metninin yanı sıra 33, 53, 67, 68, 69, 75, 84, 85, 93, 127, 135, 149. ve 171. maddeleri yeniden düzenlendi, 52. madde yürürlükten kaldırıldı.
Bu değişiklik kapsamında daha önce 19 olan seçmenlik yaşı 18′e indirildi. Siyasal partilerin yurt dışı faaliyetleri, kadın ve gençlik kolları gibi yan örgüt kurmalarını yasaklayan hükümler kaldırıldı. Yüksek öğretim elemanlarına, yasayla düzenlenecek çerçevede, siyasal  partilere üye olabilme imkanı sağlandı. Yüksek öğretimde kurumlarındaki öğrencilere de siyasal partilere üye olma hakkı .
1987′deki değişiklikle 400′den 450′ye çıkarılan milletvekili sayısı bu kez 550′ye yükseltildi.  ”Milletvekilliğinin nasıl sona ereceği” konusundaki tartışmalı hüküm yeniden düzenlendi. Yasama yılı başlangıcı Eylül ayından Ekim’e alındı. Anayasa’nın sendikalara siyasal faaliyet yasağını düzenleyen 52. maddesi yürürlükten kaldırıldı. Böylece,  sendikacıların siyasal faaliyette bulunmalarının yanı sıra sendikaların ve siyasal partilerin birbirlerine destek vermesinin önündeki engel kaldırıldı.
DGM’lerin üye yapısı
Dördüncü değişiklik 18 Haziran 1999 damgasını taşıyor.
Anayasa’nın 143. maddesinde yeniden düzenlenerek DGM’lerde yer alan asker üyelerin yerine sivil yargıçların atanması sağlandı. Bu düzenleme, daha sonraki süreçte kaldırılacak olan DGM’lerin sivilleşterilmesi anlamına geliyordu.
Özelleştirmeye anayasal güvence
Tarih 13 Ağustos 1999′yi gösteriyordu. Bu dönemde iktidarda DSP-MHP-ANAP koalisyon hükümeti vardı ve Bülent Ecevit başbakan koltuğundaydı.
1982 Anayasasına beşinci değişiklik yapıldı. Bu kez Anayasanın 47, 125. ve 155. maddeleri yeniden düzenlendi. 47. maddede yapılan değişiklikle ”özelleştirme” kavramı Anayasal güvenceye alındı. Bu kapsamda, kamu tüzel kişilerinin mülkiyetindeki işletme ve varlıkların özelleştirilmesine yönelik ilke ve yöntemlerin yasayla düzenleneceği hükme bağlandı.
Kamu hizmeti imtiyaz sözleşme ve şartlaşmalarında doğacak uyuşmazlıklarda da tahkim yolu açıldı.
Anayasanın 155. maddesinde değişiklik yapılarak, imtiyaz şartlaşma ve sözleşmeleri, Danıştay’ın inceleme yapacağı konular arasından çıkarıldı. Düzenlemeyle Danıştay bu durumlarda sadece görüş bildirebilecek konuma getirildi. Bu, 1924 Anayasası’nda benimsenen sisteme dönülmesi anlamına geliyordu.
AB müktesebatına uyum
Anayasada yapılan altıncı değişiklik 3 Ekim 2001 tarihini taşıyordu. AB müktesebatına uyum çalışmaları kapsamındaki bu düzelemeler, aynı zamanda Anayasada yapılan en kapsamlı değişiklik oldu.  Bu çerçevede Anayasa’nın başlangıç metninin yanı sıra 13, 14, 19, 20, 21, 22, 23, 26, 28, 31, 33, 34, 36, 38, 40, 41, 46, 49, 51, 55, 65, 66, 67, 69, 74, 86, 87, 89, 94, 100, 118. ve 149. maddeler ile Geçici 15. maddesinde düzenlemeler yapıldı.
Değişiklikler kapsamında, gözaltına alma ya da tutuklanmada kişilerin hakim önüne çıkarılma süreleri AİHS’ne uyumlu hale getirildi. Şüphelilerin en geç 48 saatte, toplu işlenen suçlarda ise en çok 4 günde hakim önüne çıkarılması kuralı getirildi.
”Özel Hayatın Gizliliği” başlıklı madde yeniden düzenlendi. Bu kapsamda herkese, özel hayatına ve aile hayatına saygı gösterilmesini isteme hakkı tanındı. Yazılı emir olmadıkça kimsenin konutuna girilemeyeceği, arama yapılamayacağı ve buradaki eşyaya el konulamayacağı anayasal kural olarak düzenlendi.
”Haberleşme Hürriyeti” başlıklı 22. maddede yeniden düzenlenerek, usulüne göre verilmiş hakim kararı ve yazılı emir olmadıkça, haberleşmenin engellenemeyeceği ve haberleşmenin gizliliğine dokunulamayacağı hükmü getirildi.
Düşünce ve ifade özgürlüğünün sınırları genişletildi. Milli güvenlik, kamu düzeni, kamu güvenliği ve bölünmez bütünlüğün korunması amaçlarıyla, düşünceyi açıklama ve yayma hürriyetinin sınırlanabileceği şartı Anayasa’ya konuldu.
Herkesin derneklere üye olma ya da üyelikten çıkma hürriyetine sahip olduğu yönündeki hüküm anayasa metnine konuldu. Toplantı ve gösteri yürüyüşü düzenleceklere izin almayı zorunlu tutan düzenleme kaldırıldı. Kanuna aykırı şeklide elde edilmiş bulguların delil kabul edilemeyeceği kuralı getirildi.
Kamulaştırmada, gerçek karşılıkların ödenmesi ve ödemede gecikme halinde faiz yönünden bireylerin zarara uğramamalarına ilişkin hükümler getirildi. Anayasanın 49. maddesinde yapılan değişiklikle devlete, çalışanların yanı sıra işsizleri de koruma görevi verecek şekilde düzenlendi. Asgari ücretin tespitinde, çalışanların geçim şartları ile ülkenin ekonomik durumunun gözönünde bulundurulması hükmü getirildi.
”Seçim kanunlarında yapılan değişiklikler, yürürlüğe girdiği tarihten itibaren bir yıl içinde yapılacak seçimlerde uygulanmaz” hükmü 67. madde metnine eklendi. Parti kapatmadaki 69. maddede düzenlenen ”odak olma” hali tanımlandı. Bir partinin temelli kapatılmasının, sadece Anayasa’nın 68/4. fıkrasındaki eylemlerin odağı haline gelmiş olması şartıyla mümkün kuralı getirildi. Temelli kapatılan bir partinin kurucularının ve her kademedeki yöneticilerinin 5 yıl süreyle yeni bir partinin kurucusu, yöneticisi ve deneticisi olamayacağı hükmü getirildi. Siyasi partiler için kapatmanın yanı sıra Hazine yardımından yoksun bırakılma yaptırımı da anayasla düzelemeye alındı.
Parti kapatma daha zor hale getirildi. Anayasa Mahkemesinin Anayasa değişikliklerinin iptali ve siyasi partileri kapatmada, 5′te 3 çoğunlukla karar vermesi kuralı konuldu.
Türk vatandaşlarına tanınan TBMM’ye dilekçe ile başvurma hakkı, karşılıklılık esası gözetilmek kaydıyla yabancılara da tanındı. Milli Güvenlik Kurulu bünyesine Başbakan yardımcıları ve Adalet Bakanı da dahil edildi; kurul kararlarının tavsiye niteliğinde olduğu metne işlendi.
Anayasa’nın geçici 15. maddesinin son fıkrası yürürlükten kaldırıldı.
Referandumdan döndüren değişiklik
10. Cumhurbaşkanı Ahmet Necdet Sezer’in, anayasa değişikliği paketindeki milletvekillerinin özlük ve emeklilik haklarına ilişkin maddeyi referanduma götürme kararı aldı. 86. maddedeki bu düzenleme için 21 Kasım 2001 tarihinde yeniden Anayasa değişikliğine gidildi. Bu maddede değişiklik yapan yasa 1 Aralık 2001′de Resmi Gazete’de yayımlanarak yürürlüğe girdi. Bu kapsamda, Sezer’in önceki değişiklik metnini referanduma götürme kararının konusu ortadan kaldırıldı.
Sekizinci değişiklik
1982 Anayasası’ndaki sekizinci değişiklik 26 Aralık 2002 tarihinde yapıldı. Bu kapsamda Anayasanın 76. ve 78. maddeleri yeniden düzenlendi. ”Milletvekilliği Seçilme Yeterliliği” başlıklı maddedeki değişiklikle milletvekili seçilemeyecek şartlar arasında sayılan ”ideolojik veya anarşik eylemlere” ifadesi ”terör eylemlerine” olarak değiştirildi.
TBMM üyeliğinde boşalma durumunda, Meclis kararıyla ara seçime gidilebileceği; ancak bir ilin veya seçim çevresinin TBMM’de üyesinin kalmaması halinde, boşalmayı takip eden 90 günden sonraki ilk Pazar günü ara seçim yapılması hükme bağlandı.
-Ölüm cezası kaldırıldı
Türkiye’de AK Parti iktidardaydı ve başbakan koltuğunun yeni sahibi Recep Tayyip Erdoğan’dı.
AB müktesebatına uyum düzenlemeleri kapsamındaki bir başka anayasa değişikliği paketi 7 Mayıs 2004 tarihinde kabul edildi. Anayasa’nın 10, 15, 17, 30, 38, 87, 90, 131. ve 160. maddelerinde değiştirlidi, 143. madde kaldırıldı.
Bu düzenlemeler kapsamında, kadınlar ve erkeklerin eşit haklara sahip olduğu, 10. maddede yapılan değişiklik ile Anayasa’ya konuldu. Devletin, bu eşitliğin yaşama geçmesini sağlamakla yükümlü olduğu da metinde yer aldı. Basın araçları anayasal koruma altına alındı.   Anayasa’nın, 38. maddesinde yapılan yeni düzenlemeyle ölüm cezası kaldırıldı.
Temel hak ve özgürlükler konusunda uluslararası anlaşmalar ile kanunların çelişmesi durumundaki uyuşmazlıkta, hangisinin öncelikli olacağı anayasal düzenlemeye alındı. Bu kapsamda, Anayasanın 90. maddesine bir fıkra eklenerek, uyuşmazlıklarda, uluslararası anlaşma hükümlerinin esas alınacağı ilkesi getirildi.
YÖK’e Genelkurmay’dan temsilci verilmesi uygulamasına son verildi.
Anayasanın 160. maddesindeki  ”Silahlı Kuvvetler elinde bulunan devlet mallarının TBMM adına denetlenmesi usulleri, milli savunma hizmetlerinin gerektirdiği gizlilik esaslarına uygun olarak kanunla düzenlenir” fıkrası metninden çıkarıldı.
1999′daki tümüyle sivil yargıçlardan oluşacak şekilde düzenlenen DGM’ler bu kez kaldırıldı.
RTÜK değişikliği
Anayasadaki onuncu değişiklik 21 Haziran 2005 tarihinde yapıldı. Bu kapsamda, Anayasanın 133. maddesi yeniden düzenlenerek, Radyo ve Televizyon Üst Kurulu’na (RTÜK) üye seçimine ilişkin hükümler yeniden düzenlendi.
Onbirinci değişiklik
1982 Anayasası’ndaki onbirinci değişiklik 29 Ekim 2005 tarihinde yapldı.
Bu düzenleme kapsamında Anayasanın 130, 160, 161, 162. ve 163. maddeleri değiştirildi. Sayıştay denetim kapsamı genişletildi; bütçenin hazırlanması, uygulanması ve kontrolüne ilişkin süreç yeniden düzenlendi. Anayasanın 162. maddesindeki ”genel ve katma bütçe tasarıları” ibaresi ”merkezi yönetim bütçe tasarısı” şeklinde değiştirildi.
Seçilme yaşı 25′e indi 
1982 Anayasası’nda yapılan onikinci değişiklik 13 Ekim 2006 tarihini taşıyordu. Anayasanın 76. maddesinde yapıla değişiklikle seçilme yaşı 30′dan  25′e indirildi.
Onüçüncü değişiklik
1982 Anayasası’ndaki onüçüncü değişiklik 10 Mayıs 2007 tarihinde yapıldı.
Bu çerçevede, Anayasaya Geçici 17. madde eklendi. Bu düzenlemeyle, 22 Temmuz 2007′de yapılacak seçimde; bağımsız adayların isimlerinin birleşik oy pusulasında yer almasına yönelik düzenlemeler yapılıyordu.
Cumhurbaşkanını halkın seçmesi
1982 Anayasası’nda 31 Mayıs 2007 tarihinde yapılan 14. değişiklik de önemli düzenlemeler getiriyordu. Bu kapsamda, Anayasanın 77, 79, 96, 101. ve 102. maddeleri yeniden düzenlendi; Anayasaya Geçici 18. ve Geçici 19. madde eklendi.
Milletvekili seçiminin 5 yıl yerine 4 yılda bir yapılması öngörüldü. TBMM’nin,  seçimler dahil yapacağı tüm işlerde, üye tamsayısının 3′te 1′i (184) ile toplanması  kurala bağlandı. Meclis’in, Anayasa’da başkaca bir hüküm yoksa toplantıya katılanların salt çoğunluğu ile karar vermesi, ancak karar yeter sayısının hiçbir şekilde üye tamsayısının 4′te 1′inin bir fazlasından az olamayacağı hükmü getirildi.
Cumhurbaşkanı seçiminde de köklü değişikliğe gidiliyordu. Cumhurbaşkanının 5+5 yıllık görev süresiyle ve halk tarafından seçilmesi kuralı getirildi. Bu seçimin nasıl yapılacağına ilişkin düzenlemeler ve buna ilişkin usul ve esasları düzenleme konusanda YSK’ya verilen yetkiler de anayasa değişikliğinde yer alıyordu.
Anayasa’nın, ”Seçim kanunlarında yapılacak değişikliklerin, yürürlüğe girdikleri tarihten itibaren 1 yıl içinde uygulanamayacağına” ilişkin maddesinin, Cumhurbaşkanı seçiminde dikkate alınmaması hükme bağlandı. Cumhurbaşkanı seçimine ilişkin getirilen yeni düzenlemelerin 11. Cumhurbaşkanı seçiminde uygulanmasını öngörülüyordu. Bu düzenlemeler halkoyuna sunuldu.
Onbeşinci değişiklik
Anayasa’daki 15. değişiklik 16 Ekim 2007′da gerçekleştirildi. Bu, bir bakıma, daha önceki değişiklik ve ardından oluşan yeni parlamentonun yeni cumhurbaşkanını seçmesiyle kaçınılmaz hale gelmişti. Bu kapsamda,  ”Seçim kanunlarında yapılacak değişikliklerin 11. Cumhurbaşkanı seçiminde uygulanması”na imkan sağlayan Geçici 18. madde ile ”Cumhurbaşkanı seçimine ilişkin getirilen yeni kuralın 11. Cumhurbaşkanı seçiminde de uygulanmasını” öngören Geçici 19. madde Anayasa metninden çıkarıldı.
Anayasa Mahkemesi iptal etti
1982 Anayasası’nın 10. maddesi 9 Şubat 2008 tarihinde değiştirildi. ”Üniversitelerde türbanı serbest bırakan düzenleme” olarak da nitelenen değişiklik kapsamında, ”devlet organları ve idare makamlarının, bütün işlemlerinde olduğu gibi her türlü kamu hizmetlerinden yararlanılmasında kanun önünde eşitlik ilkesine uygun olarak hareket etmek zorunda olduğu” kurala bağlanıyordu. Anayasa 42. maddede yapılan değişiklikle ise yüksek öğretimde başörtüsünün serbest bırakılmasına ilişkin hüküm kabul edilerek, kanunda açıkça yazılı olmayan herhangi bir sebeple, kimsenin yüksek öğrenim hakkını kullanmaktan mahrum edilemeyeceği belirtildi.
Yapılan bu değişiklikler Anayasa Mahkemesi’nce iptal edildi
Darbe yönetimine yargı yolu
1982 Anayasası’nda yapılan 17. ve son değişiklik 7 Mayıs 2010 tarihli kanunla yapıldı. Bu düzenlemeler, 12 Eylül 1980 askeri müdahalesinin 30′uncu yılında halk oylamasına sunularak kabul edildi.
Bu değişiklikler 1982 Anayasası’nın 23 maddesi ile Geçici 15, 18 ve 19. maddelerini kapsıyordu. Anayasanın Geçici 15. Maddesi’nin yürürlükten kaldırılması 12 Eylül darbesi yöneticilerine yargı yolunun açılması anlamına geliyordu. Sendikal yaşam, ekonomi ve sosyal konulara ilişkin düzenlemeler Anayasanın 10, 20, 23, 41, 51, 53, 54, 74, 84, 94, 125, 128, 129, 144, 145, 146, 147, 148, 149, 156, 157, 159, 166. madelerini kapsıyordu.
Yapılan değişikliklerdeki bazı hükümler Anayasa Mahkemesince iptal edildi. Anayasa değişikliği ise  12 Eylül 2010 tarihinde halkoyuna sunuldu ve kabul edildi.
–
Kaynaklar: TBMM kayıtları, ”551.vekil” arşivi, süreli yayınlar


Anayasal Bilgiler (Soru Cevaplar): 
• 1-Osmanlı Devletinin yönetim biçimi 1876 anayasası öncesinde nasıldır? Mutlak monarşi
2-Türk Hukuk sisteminde ilk anayasal girişimin adı nedir?Senedd-i ittifak
3-Osmanlı Devletinin ilk anayasası hangisidir? 1876 Kanun-i Esasi
4-Egemenliğin millete ait olduğu,ilk kez hangi anayasa ile kabul edilmiştir?1921 Anayasası.
5-Laiklik ilkesi anayasamıza ilk kez ne zaman girmiştir? 1937(1924 anayasasında yapılan değişiklikle)
6-Devletin dini İslam’dır ibaresi ne zaman çıkartılmıştır?1928(1924 anayasasında yapılan değişiklikle)
7Çok partili siyasi hayat ilk kez hangi anayasa döneminde başlamıştı?1924
8-Hangi hallerde ve kim tarafından seçimlerin ertelenmesine karar verilebilir? Savaş hali/TBMM
9-TBMM ve yerel yönetimler seçimleri kaç yılda bir yapılır? 5
10-Süresi dolmadan meclis seçimlerine kim karar verir? TBMM
11-Meclis çalışmalarını hangi düzenlemeye bağlı olarak yürütür? Meclis iç tüzüğü
12-Yasama dokunulmazlığı kaldırılan milletvekili nereye müracaat edebilir? Anayasa mahkemesi
13-Yasama sorumsuzluğunun kapsamı nelerden ibarettir? :Oy,söz ve düşünce
14-Türkiye’de uygulanan genel seçim barajı yüzde kaçtır? 10
15-Türkiye’de yapılan seçimlerin denetimi ve gözetimini sağlayan kuruluş kimdir? Yüksek seçim kurulu
16-Ara seçimlere hangi hallerde gidilir? TBMM üyeliğinin %5’ini boşalması Bir ilin veya seçim çevresinin TBMM hiç üyesinin kalmaması.
17-Yasama dokunulmazlığını kaldıran karar organının adı nedir? Anayasa mahkemesi
18-Genel seçimlere ne kadar süre kala/ süre geçmedikçe ara seçim yapılamaz? 1 yıl kala/30 ay geçmedikçe
19-Milletvekilinin seçimden önce veya sonra işlediği ileri süren bir suç nedeniyle tutuklanamamasına,sorguya çekilememesine,yargılanamaması na ne ad verilir? Yasama dokunulmazlığı
20-Millet vekilliğini düşüren halleri maddeleyiniz? İstifa,**üm ve gaiplik, Milletvekili seçilmeye engel bir suçtan hüküm giyme, Mecliz çalışmalarına izinsiz ve özürsüz 5 birleşim günü katılmama, Milletvekilliği görevi ile bağdaşmayan bir işi sürdürmekte ısrar etme
21-TBMM’nin hükümeti denetleme yollarını yazynız? Soru,Gensoru,Meclis araştırması,Meclis soruşturması
22-Meclis denetim yollarından hangisi hükümetin siyasi sorumluluğunu doğurur? Gensoru ve meclis soruşturması
24-TMBB’yi doğrudan toplantıya çağırabilecek olan kişiler? Cumhurbaşkanı/Meclis başkanı
25-Cumhurbaşkanına kim vekalet eder? Meclis başkanı
26-Meclis başkanı kim tarafından seçilir? TBMM
27-TBMM toplantı ve karar yeter sayısı hangisinde sırasıyla doğru verilmiştir? Meclisin 3/1 ile toplanır ve salt çoğunlukla karar verir.Ancak karar yeter sayısı meclis üye sayısının 4/1 altında olamaz.
28-Yürütme işlevini üstlenen kuruluşları yazınız? Cumhurbaşkanı/Bakanlar kurulu
29-“Meclis hükümeti sisteminden vazgeçilerek parlementer sisteme geçilmiş ve iki başlı yürütme biçimi benimsenmiştir.”yukarıdaki değişiklik hangi anayasayla yapılmıştır? 1924 Anayasası.
32-Cumhurbaşkanının istisnai ceza sorumluluğu dışındadır? Vatana ihanet
33-Genelkurmay Başkanlığı hangisine karşı sorumludur? Başbakan
34-TBMM genel seçimlerinden önce çekilen bakanlar hangileridir? Adalet,İçişleri,Ulaştırma bakanlıkları
35-Devlet denetleme kurumu kime bağlıdır.Hangi alanları denetleyemez? Cumhurbaşkanlığına,Askeri ve Adli kurumları
36-Ulusal güvenlik politikaların oluşturulmasında hükümete yardımcı olan kuruluş? MGK(Milli Güvenlik Kurulu)
37-Bakanlıkla ilgili önemli bilgiler oluşturunuz? Başbakanın önerisi üzerine Cumhurbaşkanı tarafından atanır ve görevden alınırlar. Bakanlar kurulu oy birliği ile karar alır.
Bir bakan en fazla bir bakana vekalet edebilir. Yüce divana giden bakanın görevi sona erer. Gensoru yoluyla bakanların siyasi sorumluluğuna gidilebilir.
38-Kanun hükmünde kararname çıkarma kim tarafından kime verilir? TBMM tarafından Bakanlar kuruluna verilir.
39-Kanun hükmünde kararnameler genel olarak ne zaman yürürlüğe girer? Resmi gazetede yayımlandıkları gün.
40-Kuvvetler birliğini oluşturan unsurlar nelerdir?Ve kimler trf. Kullanılır? Yasama—TBMM Yürütme–Cumhurbaşkanı/Bakanlar kurulu Yargı—Bağımsız Türk mahkemeleri
41-Yüksek mahkemeleri yazınız? Anayasa mahkemesi,Danıştay,Yargıtay,As keri Yargıtay,Askeri yüksek İdare mahkemesi,uyuşmazlık mahkemesi. (Sayıştay/YSK Yüksek mahkeme değildir)
42-“Hakim ve savcılar azlolunamazlar,kendileri istemedikçe anayasada gösterilen yaştan öne emekliye ayrılamazlar”.Yukarıda anlatılan ilke nedir? Hakimlik teminatı
43-Hakim ve savcılar Yüksek kurulu başkanı aşağıdakilerden hangisidir? Adalet bakanı.
44-Hakim ve Savcılar Yüksek kurulu üyeleri-Adalet başkanı ve müsteşarı hariç-kim tarafından atanır?Ve üyelerinin görev süresi ne kadardır? Cumhurbaşkanı tarafından 4 yıl süreyle.
45-Kanun Hükmünde Kararnamelerin Anayasaya uygunluğunu kim yapar? Anayasa mahkemesi.
46-Anayasa mahkemesi tarafından sadece şekil yönünden denetlenir? Anayasa değişikliği.
47-Adliye mahkemelerince verilen karar ve hükümlerin temyiz mercii neresidir? Yargıtay.
48-İdari mahkemelerince verilen karar ve hükümlerin temyiz mercii neresidir? Danıştay
49-Askeri mahkemelerince verilen karar ve hükümlerin temyiz mercii neresidir? Askeri Yargıtay
50-Hakim ve savcılar kim tarafından denetlenirler? Adalet bakanlığı.
51-Anayasa mahkemesi başkanını kim seçer? Anayasa mahkemesi üyeleri.
52-Anayasa mahkemesi üyelerini kim seçer? Cumhurbaşkanı.
53-Anayasa mahkemesi kararlarıyla ilgili birkaç not yazınız? İptal kararları geriye yürümez.
Anayasa mahkemesi kararları kesindir.devletin bütün kurumlarını ve gerçek/tüzel kişileri kapsar.
İptal edilen hükümler,iptal kararının resmi gazetede yayımlandığı tarihte yürürlükten kalkar.Anayasa mahkemesi iptal hükmünün gireceği tarihi ayrıca karalaştırabilir.Bu süre kararı Resmi gazetede yayımlandığı günden başlayarak 1 (Bir) yılı geçmez.
Anayasa mahkemesi bir hükmü iptal ederken kanun koyucu gibi hareket ederek,yeni bir uygulamaya yol açacak biçimde hüküm tesis edemez.
54-Yargıtay üyeleri kim tarafından şeçilir? Hakim ve Savcılar Yüksek Kurulu.
55-Anayasa kaç maddeden oluşmaktadır? 177
56-Anayasamızın ilk maddesini yazınız? Türkiye Devleti bir Cumhuriyettir.
57-Vatandaş Kime denir? Türkiye’ye vatandaşlık bağı ile bağlı olan herkese vatandaş denir.
58-Bir siyasi partinin kapatılmasına neden olan yöneticiler kaç yıl ceza alırlar? 5
59-Siyasi partiler hangi mahkemenin kararıyla kapatılırlar? Anayasa mahkemesi.
60-Seçim dönemi dolmadan seçimlerin yenilenmesine karar verilerek yapılan seçime ne ad verilir? Erken seçim
61-Yüksek Seçim Kurulunun kararları aleyhine hangi mercie başvurulur? YKS karaları kesindir.Başvurulamaz…
62-Bir seçim döneminde en fazla kaç defa ara seçime gidilir?Koşulları nelerdir.2(iki)kez..Bir ilin veya seçim bölgesinin TBMM üyesi kalmaması.
63-Milletvekili tarafından yapılan kanun önerisine ne ad verilir? Kanun teklifi.
64-Bakanlar Kurulu tarafından yapılan kanun önerisine ne ad verilir? Kanun tasarısı.
65-hükümet olmayan,mecliste temsil olunan partilerden en fazla milletvekiline sahip partiye ne ad verilir? Ana muhalefet partisi.
66-Birden fazla partinin bir araya gelerek hükümet kurmalarına ne ad verilir? Koalisyon.
67-Salt çoğunluk nedir? Meclis üye tamsayısının bir fazlası(550/2+1)
68-Milletvekilleri hangi sosyal güvenlik kurumuna tabidir? T.C Emekli Sandığı
69-Milletvekiline sağlanan mali imkanların tamamı hangi şıkta verilmiştir? Ödenek-yolluk-emeklilik imkanı.
70-Henüz kanunlaşmamış kanun tasarısının ömrü ne kadardır? Hükümetin ömrüyle sınırlıdır.
71-Anayasamıza göre kanun hükmünde kararname hangi nitelikleri taşımalıdır? Önemli olma,kısa süreli olma,Zorunlu olma ve sosyal/eko.haklarla ilgili olma.
72-Anayasamıza göre doğrudan iptal davası açabilme hakkı kimlere
aittir? Cumhurbaşkanı,İktidar ve ana muhalefet partisi.
73-Tüzükler hakkında kısa notlar yazınız? Kanunların uygulanmasını göstermek veya emrettiği işleri belirtmek, Kanunlara aykırı olamazlar, Danıştay’ın incelemesinden geçerler, Bakanlar kurulunca çıkarılır.
74-Yönetmelik çıkarma yetkisi sadece kime aittir? Kamu tüzel kişiliğine sahip olan kurumlar.
75-Cumhurbaşkanına ilk kez 1982 anayasasıyla hangi değişiklik getirilmiştir? Başbakanını önerisi üzerine bakanların görevine son vermek, Cumhurbaşkanının dışarıdan seçilmesine olanak sağlanması.
76-Sosyal düzen kuralları nelerden oluşmaktadır? Hukuk,gelenek-görenek,Din kuralları,ahlak kuralları,Görgü kuralları.
76-Hukukun diğer sosyal kurallarından temel farkı nedir? Yaptırımı devlet zoruna dayanması-Kamu gücünü barındırması.
77-Bir kuralın hukuk niteliği taşıması için gerekli olan üç şey nedir? Yazılı,sürekli,genel olması gerekir.
78-Kurallar hiyerarşisinin en üst sırasındaki norm hangisidir? Anayasa daha sonra kanun,KHK,tüzük,yönetmelik.
79-Hangi hukuk dalında örf ve adete yer verilmez? Ceza hukuku.
80-Bölge idare mahkemesi hakkında kısa notlar tutunuz? Adalet bakanlığınca kurulur.İdare ve vergi mahkemesinin tek hakimle verdiği kararlara karşı yapılan itirazları kesin olarak karara bağlar.
81-Ceza mahkemeleri genellikle hangi davalara bakmaktadır? Dolandırıcılık,Hırsızlık,Yaral ama ve Cinayet.
82-Yetkili bir makam tarafından olan ve hala yürürlükte bulunan hukuk kurallarının tümüne ne ad verilir? Pozitif Hukuk.
83-Normal erginlik hangi yaşın doldurulmasıyla kazanılır? 18
84-1982 anayasasına göre değiştirilemeyecek hükümler nelerdir? Türkiye Devleti bir Cumhuriyettir.
Atatürk milliyetçiliğine bağlı,insan haklarına saygılı,Laik,demokratik,soysa hukuk devletidir. Milli marşı İstiklal Marşıdır. Başkenti Ankara,Dili Türkçe’dir
85-1921 Anayasasının getirdiği en temel yenilik nedir? Milli Egemenlik
86-1982 anayasasında temel hak ve hürriyetlerin sınırlandırılmasında dikkate alır? Milletlerarası hukuktan doğan yükümlülüklerin ihlal edilmemesi, **çülülük ilkesi,
Demokratik toplum düzenin gerekleri, Anayasanın sözüne ve ruhuna aykırı olmaması.
87-Türk Tarihindeki tek yumuşak anayasamız hangisidir? 1921 Anayasası.
88-Hangileri KHK ile düzenleme imkanı yoktur? Bütçe,Temel haklar,Kişi hakları,Siyasi haklar.
89-Yasama dokunulmazlığının kaldırılması ve üyeliğin düştüğüne dair meclis kararının iptali Anayasa mahkemesinden ne kadar süre içinde istenebilir? Bir hafta (7 gün)
90-Kanun hükmünde kararnameler hangi anayasal düzenleme ile gelmiştir? 1961 Anayasasında 1971 değişikliğiyle.
91-Türkiye Büyük Millet Meclisi bir yasama yılında en fazla ne kadar tatil yapar? 3(Üç) ay.
92-Yasama organının bir konuyu araya işlem girmeksizin doğrudan doğruya düzenleyebilmesi hangisi ile ifade edilir? Yasama ilkelliği.
93-Siyasi partilerin mali denetimini ve temelli kapatılmasına kim karar verir? Anayasa mahkemesi.
94-Anayasa mahkemesini şekil bakımından iptal davası,değişikliğin yayını tarihinden itibaren kaç gün içinde alınabilir? 10 (On) gün içinde…
96-Hakimlik teminatının en önemli unsuru nedir? Hakimlerin azlolunmaması ilkesi.
97-Bir mahkemede görülmekte olan davanın karara bağlanmasının,karar etkisi olacak normun anayasaya uygun olup olmamasına bağlı olduğu durumda yapılan denetime ne ad verilir? Somut norm denetimi
98-Somut norm denetiminde Anayasa mahkemesinin ne kadar süre içinde karar vermesi gerekir? 5 (Beş) ay
99-Halkın doğrudan katılmasını sağlayan yönteme ne ad verilir? Referandum.
100-Koruyucu hak ne demektir? Bireyi,devlete ve topluma karşı koruyan hak.
101-1982 Anayasasına göre,aşağıdakilerden hangisi TBMM’ye karşı,milli güvenliğin sağlanmasından sorumludur? Bakanlar Kurulu
102-1982 Anayasasında “Siyasi partiler,önceden izin almadan kurulurlar”hükmü hangi temel ilkenin bir gereğidir? Demokratik devlet
103-1982 Anayasasına göre TBMM’de aşağıdakilerden hangisinin gizli oyla yapılması zorunludur? Cumhurbaşkanın seçilmesi.
105-1982 Anayasasına göre Cumhurbaşkanının tek başına yapabileceği işlemlerin yargısal denetimi ile ilgili olarak ne söylenebilir?Bu işlemlere karşı yargı yoluna gidilemez.
106-Demokratik bir toplumda halk yöneticilerini nasıl belirler? Seçim ile.
107-1982 Anayasasına göre,Cumhurbaşkanı tarafından hükümeti kurmakla görevlendirilen kişinin,mutlaka taşıması gereken koşul nedir? Milletvekili olması(Meclis üyeliği)
108-1982 Anayasasına göre açık olan bakanlıklarla izinli veya özürlü bakanlara kim vekalet eder? Bakanlardan biri.
109-Dilekçe hakkı nedir? Vatandaşların kendileriyle ilgili dilek ve şikayetleri hakkında yetkili makamlara ve TBMM’ye yazı ile başvurma hakkıdır.
110-Köyde bulunan bütün seçmenlerin bulunduğu kurula ne ad verilir? Köy derneği.
111-Emlak vergisi veya veraset ve intikal vergisinin aşırı ölçüde yükseltilmesi,aşağıdaki temel hak ve özgürlüklerinden hangisini kısıtlar? Emlak,arsa,konut taşınmaz mallar olup,Mülkiyet hakkını kısıtlar.
112-Parlementer sistemin ayrıcı bir özelliğini yazınız? Yürütme organının yasama organından kaynaklanması ve ona karşı sorumlu olması.
113-1982 Anayasasında yer alan ”Türkiye Devleti ülkesi ve milletiyle bölünmez bir bütündür ”hükmü hangisinin doğal sonucudur. Milli egemenlik.
114-Türk Tarihindeki ilk yazılı anlaşmanın adı nedir? 1876 Kanun-ı Esasi
115-1982 Anayasasına göre Cumhuriyetin nitelikleri nelerden oluşur? İnsan haklarına saygılı,Laik,Demokratik,sosyal hukuk devleti.
116-Türk vatandaşlığını kanıtlamada kullanılabilecek belgeler nelerdir? Nüfus cüzdanı,Nüfus kayıtları,pasaport,pasavan ve ehliyet.
117-Bir kimsenin kendi şahsına ve malına yapılan ve halen devam eden hukuka aykırı bir saldırıyı önlemek için yaptığı karşı saldırı niteliğindeki eyleme ne ad verilir? Meşru müdafaa.
118-Türkiye’nin taraf olduğu Milletler arası sözleşme çerçevesinde hangi kurumun zorunlu yargı yetkisini kabul etmiştir? Avrupa İnsan Hakları mahkemesi.
119-1982 Anayasasına göre savaş,seferberlik,sıkıyönetim ve olağanüstü hallerde milletlerarası hukuktan doğan yükümlülükler ihlal edilmek kaydıyla aşağıdaki temel hak ve hürriyetlerden hangisinin kullanılması durdurulamaz? Vicdan hürriyeti
ali konferansı başladı. Yaklaşık 200 ülkeden temsilciler, iklim değişikliği ile mücadele yollarını görüşmek üzere Endonezya’nın Bali kentinde biraraya geldi.
Birleşmiş Milletler’in öncülüğünde bugün başlayan iki haftalık toplantıda, geçerlik süresi 2012 yılında dolacak olan Kyoto Protokolü’nün yerini alacak yeni bir anlaşma için müzakere çerçevesi ve takvmi belirlenmesi öngörülüyor.

Adli Terimler:

Adli sicil kaydı: Kesinleşmiş mahkumiyet kararlarını gösterir kayıt.
Aleniyet: Açıklık, izlenebilirlik.
Ara karar: Son hüküm olmayıp hükme giden yolda verilen ara, yardımcı kararlar.
Arama (Adli arama): Hâkim kararı ile yapılan ev ve işyeri araması.
Arama (Önleme araması): Suçun işlenmeden önceki aşamasında idarece
yürütülen arama biçimi.
Ayırma (Davaların ayrılması): Fiili ya da hukuki bağlantısı olmayan veya birisi
hakkında verilecek kararın diğer davayı etkilemeyeceği durumlarda
davaların ayrılarak yürütülmesi.
Bağlantı (Davalar arası): İrtibat, bir dava hakkında verilecek karar diğerini
etkileyebilecek durumda olması.
Beraat: Suçlu bulunmama hali, başlangıçtan beri kirlenmemiş olma.
Bihakkın (Tahliye): Şart olmaksızın, hakkıyla cezasını çekmiş, tüketmiş olma.
Bilirkişi (Ehl-i vukuf): Alanında görüşüne başvurulacak kadar uzman.
Birleştirme (Davaların birleştirilmesi): Aralarında bağlantı olan, biri hakkında
verilecek kararın diğer dava sonucu etkileyecek olması durumunda
her iki davanın birlikte yürütülmesi.
Bono: Türk Ticaret Kanunu’nda düzenlenen, alacağın miktarını, borçlusunu ve
ödenme zamanını gösteren belge.
Butlan: Hukuki işlemin hiç doğmamış sayılması, yok sayılması.
Cebri icra: Zorla yerine getirme.
Celse: Oturum, duruşma.
Ceza fişi: Kesinleşen kararların türü ve miktarına ilişkin adli sicil (sabıka)
kayıtlarına işlemek üzere düzenlenen ve adli sicile sevkedilen evrak.
Ciranta: Bir senedi ciro eden kimse.
Ciro: Bir senet veya havalenin alacaklı tarafından diğeri namına çevrilmesi ile
üzerine buna dair şerh verilmesi.
Çağrı kâğıdı: Cumhuriyet Savcılığı aşamasında dinenmesi gereken şüpheli,
mağdur ve tanıkların gelmesini isteyen kağıt.
Daimi arama: Faili bulunamayan suçların araştırıldıkları dosyalara verilen isim.
Davaname: Cumuriyet savcısının konuyu ilgilendiren ancak ceza davası niteliği
taşımadığı için hukuk mahkemelerinde görülecek olan davayı açtığı
belge.
Açıklama: Özellikle mahkemeler, genel olarak da adliyelerin günlük
işleyişinde sıkca kullanılan hukuki terimlerden bir kısmı kitabın daha kolay
anlaşılması amacıyla listelenerek kısaca açıklanmaya çalışılmıştır. Terimlerin
açıklamaları Türk Dil Kurumu güncel türkçe sözlük ve çeşitli hukuk
sözlüklerinden yararlanılarak hazırlanmıştır.
Davanın kabulü: Dava dilekçesindeki istemi bütünü ile veya kısmen kabul eden
hukuk mahkemesi sonuç kararları.
Davanın reddi: Dava dilekçesindeki istemi bütünü ile veya kısmen reddeden
hukuk mahkemesi sonuç kararları.
Davetiye: Duruşmaya çağrı kağıdı.
Davetname: Çağırmaya yetkili makamların kişinin hazır olması bakımından
çıkarılan çağrı kağıdı.
Delil: Bir vakıanın varlığını ortaya koyan vasıta, işaret.
Denetimli serbestlik: Cezaevine girmeksizin, dışarıda bazı kurallara uyma
zorunluluğu.
Disiplin hapsi: Yargılama sürecinde düzen bozuculara karşı , temyizi ve itirazı
kabil olmayan, şartla tahliyesi bulunmayan 4 günü geçmeyen
uslandırma amaçlı bir hapis türü.
Düplik: Davanın replik (cevaba cevap) yazısına karşı davalının vermiş olduğu
cevap; ikinci cevap.
Düşme kararı: Yürüme şartını kaybeden davaların görülemeyeceğine ve sükutuna
ilişkin karar.
El koyma: Suça konu veya delil niteliği olan eşya ve malın Cumhuriyet Savcılığı
ve mahkeme aşamasında alıkonulması.
Emanet: Alıkonulan eşya,mal veya paranın yargı kararı kesinleşinceye kadar
adliyede, Cumhuriyet Savcılığı bünyesinde bir deftere konularak
muhafazası.
Emanet memuru: Emanet eşya işleri ile uğraşan memur.
Fail: Hareketi gerçekleştiren kişi (özne), suçu işleyen.
Faili meçhul: Kim tarafından işlendiği bilinmeyen hadiseler.
Fezleke: Hülasa netice yazısı (soruşturma evrakının özeti), özel anlamıyla ağır ceza
mahkemesinin bulunmadığı ilçelerde meydana gelen olayların, ağır
ceza mahkemesi görev alanına girdiğinde, bütün deliler toplanarak
merkez Cumhuriyet Başsavcılıklarına gönderilen iddianame öncesi
sonuç yazısı.
Gaip: Yokluğu farzedilen kişi, bulunduğu yer bilinmeyen, yurt dışında olup da
getirilemeyen veya getirilmesi uygun olmayan kişi.
Gerekçeli karar: Duruşma bitiminde verilen son kısa hükmün gerektirici
sebeplerini içeren mahkeme kararı.
Görev: Kanunla tespit edilen ve bir mahkemenin yargılama alanını gösteren
terim.
Gözaltı: Ortaya çıktığı düşünülen bir suçun araştırılması, delillerin karartılmasının
engellenmesi ve kişinin sorgusu için şüphelinin savcı talimatı ile;
kanunda belirtilen sürece alıkonulması.
Haciz: Alacaklının talebi ve yasal koşulların oluşması halinde borçlunun malları
üzerine satılamaz şerhinin konulması ve gerekirse malın yed-i
emine teslimini gösteren hukuki tanım.
Hak düşürücü süre: Var olan bir hakkın kullanılmaması halinde belirli bir süre
sonunda bu kullanım hakkını düşüren süre.
Hak ehliyeti: Hukuki işlem yapabilme ehliyeti, alacak sahibi olma, borçlanabilme
yeteneği.
Hâkimin reddi: Yasada yazılı nedenlerle davaya bakması adaletin yerine
getirilmesini engelleyeceği düşünülen hâkimin davaya bakmamasını
talep etme.
Hakkın kötüye kullanılması: Hukukun korumadığı hak kullanma biçimi.
Haksız fiil: Hukukun korumadığı, hakka dayanmayan fiil.
Hapsen tazyik: Hapisle zorlama, hukuka aykırı hareket edeni uslandırma,
hukuka uymaya zorlama hapsi.
Harç: Resmi bir muamele başvurusu yapılırken ödenmesi gereken yasal meblağ.
Harç tahsil müzekkeresi: Kesinleşen kararlara ilişkin harçların tahsili için
maliyeye yazılan yazı kağıdına verilen ad.
Heyet: Üç veya daha fazla hâkimin bir arada çalışması.
Hukuki ihtilaf: İçerisinde suç barındırmayan, ceza soruşturmasına konu olmayan
çekişme.
Hukuki işlem: Yasadan kaynaklanan ve hukuk alanında sonuç doğuran işlemler.
Hükmen tutuklu (Hükümözlü): Hakkında ilk derece mahkemesinin mahkumiyet
kararı verdiği ve tutuk halinin devamına hükmettiği kişinin hukuki
durumu.
Hükmün açıklanmasının geri bırakılması: Sanık hakkında 2 yıl ve daha az
mahkumiyet sözkonusu olduğunda ve yasal şartlar çerçevesinde;
verilen kararı açıklamadan sonuç doğurmayacak bir alana terk etme.
Hüküm fıkrası: Son kararın yer aldığı duruşma sonu yazılan bölüm.
İcra: Kanunen yükümlü olan tarafça yerine getirmesi gereken bir edimin veya
hareketin yerine getirilmemesi halinde; devlet gücü ile yerine
getirilmesi.
İddianame: Şüpheli hakkında mahkemeye sunulan ve cezaladırma talebini içeren
Cumhuriyet Savcılığı yazısı.
İflas: Borçların ödenememesi hali.
İhzar (Zorla getirme): Kolluk gücü ile mahkemeye zorla getirme.
İlam: Kesinleşmiş ve yerine getirilmesi gereken mahkeme kararı.
İncelenmeksizin ret: Esas incelemeye konu olamayacak başvurunun usuli yoldan
reddi.
İnfazın ertelenmesi: Belirli mahkumiyetlerin infazının, geçerli mazeret ve
koşulların varlığı halinde ileriye tehiri.
İptal: Hukuki işlemin geçersizliğinin tespiti.
İsticvap: Bir tarafın kendi aleyhine olan belli bir (veya birkaç) vakıa hakkında
mahkeme tarafından sorguya çekilmesi.
İstinabe: Mahkeme mahallinde bulunmayan ve mahkemece dinlenmesi
gereken kişinin, yargılayan mahkemenin talebi ile oturduğu yer
mahkemesince dinlenmesi.
İştirak: Bir fiile birden çok kişinin katılımı.
İtiraz: Yapılan bir hukuki işleme veyahut verilen bir karara karşı; kanunun
gösterdiği şekilde ikinci bir kez inceleme istemi.
İzalei şüyu (Ortaklığın giderilmesi): İştirak halindeki mülkiyetin paylaştırıması
işlemi.
Kalem: Mahkemeler ve Cumhuriyet savcılıklarının yazı işlerini yürüten birimi.
Kambiyo senedi: Yasaca ayrıcalıklı korunan senet türü.
Kamu düzeni: Yasaların öngördüğü ve toplumun genelini ilgilendiren uyum hali.
Kamu yararı: Toplumun geneline ve düzene yansıyan yarar.
Kanun yararına temyiz (Yazılı emir): Hukuka aykırı bir sonuç doğuran ancak
Yargıtay incelemesinden geçmeksizin kesinleşen hükümlerle ilgili
olarak Adalet Bakanlığı ile Cumhuriyet Başsavcılığı tarafından
başvurulan bir kanun yoludur, amacı ise yanlış hukuki kararların
yerleşmesini ve örnek alınmasını engellemektir.
Karar düzeltme: Yargıtay ilgili dairesinin bozma veya onama kararından sonra;
açık bir hukuka aykırılık görüldüğünde son kez aynı daireden
kararını tekrar gözden geçirmesine ilişkin istemin kabulü.
Kararın tavzihi / açıklanması: Verilen kararda belirsiz hususların kararı veren
merci tarafından açıklığa kavuşturulması.
Katılan (Müdahil): Davada taraf olan ve yasanın dava taraflarına verdiği hakları
kullanan kişi.
Kayıt tashihi / düzeltmesi: Herhangi bir resmi kayıttaki yanlışlığın mahkeme
yoluyla düzeltilmesi.
Kesinleş(tir)me: Hukuki yolları tüketen bir yargı kararının sonuç doğurması için
mahkemece düşülen şerh.
Kısa karar: Duruşma sonrası verilen ve henüz gerekçesi yazılmayan karar.
Kolluk: Güvenlik birimleri.
Komisyon (Adli Yargı Adalet Komisyonu): Ağır ceza mahkemesi bulunan
yerlerde teşkilatlanan, başkanı Hakimler ve Savcılar Yüksek Kurulu
(HSYK)nca atanan, bir üyesi Başsavcı, diğer üyesi ise yine HSYK’ca
belirlenen, personel işlerini yürüten kurul.
Konkordato: Dürüst borçlunun önerip de en az üçte iki alacaklısının kabulü
ve ticaret mahkemesinin onaması ile ortaya çıkan bir anlaşmayla,
alacaklıların bir kısım alacaklarından vazgeçmesi ve borçlunun da bu anlaşmaya göre kabul edilen borcun belli yüzdesini, tamamını ya da daha fazlasını, kabul edilen vadede ödeyerek borcundan
kurtulması.
Kovuşturma: Ceza davasının mahkeme evresi; yargılama safhası.
Layiha: Herhangi bir konuda bir görüş ve düşünceyi bildiren yazı; tasarı.
Maddi hata: Esasa ilişkin olmayan, yazıda ve rakamda yanılgıyı gösterir hata.
Mahcuz (Hacizli): Üzerinde satılamaz şerhi bulunan menkul / gayrımenkul her
türlü eşya veya değer.
Mahkum (Hükümlü): Mahkumiyet kararı kesinleşen sanık.
Mahsup: Daha önce tutuklu kalıp beraat eden kişinin bir sonraki eylemi sonucu
aldığı mahkumiyetten önceki tutukluluk süresinin düşülmesi; hesap
etmek, hesaba geçirmek.
Malen sorumlu(luk): Cezai yönden değil malvarlığı ile sorumlu(luk).
Men’i müdahale: Bir gayrımenkulun haksız işgali halinde açılan dava ve sonuçta
verilen karar.
Mevcutlu: Kolluk tarafından bir soruşturma evrakı getirilirken, soruşturmaya
konu şahısların da birlikte getirilmesi.
Müdafi: Savunman, vekalet ilişkisi olmaksızın yasa gereği şüpheli ve sanığı
savunan avukata verilen yasal isim.
Müddeabih: Hukuk davasının konusu, talep edilen şey.
Müddetname: Hükümlünün cezasını formüle eden Cezaevine girilmesi ve
çıkılması gereken zamanla beraber, yasal ceza indirimlerini de konu
eden savcılık kâğıdı.
Müsadere: Kendiliğinden suç teşkil eden veya suçta kullanılan eşyanın zoralımı.
Müşterek: Pay üzerinde tasarruf edilebilen ortaklık hali.
Mütalaa: Görüş.
Mütemmim cüz: Bütünün vazgeçilmez parçası.
Müteselsil: Birbirini izleyen, zincirleme.
Müvekkil: Vekalet veren, avukatın vekilliğini yaptığı kişi.
Müzakere: Karşılıklı konuşma, tartışma.
Müzekkere: İstem yazısı.
Nüfus tashihi: Ad, soyad ve yaş düzeltme işlemlerinin genel adı.
Replik: Davacının, davalının cevap layihasına (yazısına) karşı verdiği cevap;
cevaba cevap.
Resen: Kendiliğinden.
Resim ve harç: Vergi isimleri.
Sanık: Hakkında kamu davası açılan şüpheli.
Savunma: Şüpheli veya sanığın üzerine atılı suç isnadına karşı, aleyhindeki
delilleri bertaraf etmek üzere kendisi ile fiil arasındaki ilişkiyi,
kendi görüşüyle ortaya koymak, kendi görüşüne ilişkin olarak delil
toplanmasını talep etmek.
Sorgu: Şüpheli veya sanığın hâkimce ifadesinin alınması ve soru sorulması.
Soruşturma: Savcılığın iddianamenin kabulü aşamasına kadar suç ve şüpheli
hakkında yaptığı incelemeler.
Soruşturma izni: Haklarında belirli durumlarda soruşturma amirin iznine tabi
kişiler hakkında verilen izin.
Suç eşyası: Suçta kullanılan veya kendiliğinden bulundurulması suç olan eşya.
Suçtan zarar gören: Mağdur.
Sübut: Suçun delillendirilmesi, ispat hali.
Süre: Hukuki işlemlerin ortaya konması gereken zaman..
Şartla salıverme: Cezasının bir kısmını çeken hükümlünün iyi hali gözetilerek,
geri kalan kısmını dışarıda geçirmesi ve bu sürede tekrar suç
işlememesi şartını içeren durumdur.
Şikâyetçi (Müşteki): Şikâyet eden, şikâyete hakkı olan.
Şüpheli: Soruşturmaya konu olan kişi.
Tahliye: Haksız yere bir taşınmazı işgal eden kişinin devlet gücü ile taşınmadan
çıkarılması; hükümlü ve tutuklunun cezaevinden çıkarılması.
Talep: İstem, isteme.
Talimat: Bir yer Savcılığı veya mahkemesinin diğer yer savcılık veya
mahkemesinden soruşturma veya dava için bir işlem yapması
istemi.
Tanık: Soruşturma veya dava konusu ile ilgili bilgisi olan ve dinlenmesine karar
verilen kişi.
Tebellüğ: Bir bildiriyi imza karşılığı alma.
Tebliğ: Bir kararı muhatabına resmi olarak iletme.
Tedbir: Henüz kararı verilmeyen konularda ,dava sonuna kadar belirli önlemlerin
alınması.
Tekemmül: Tamamlama.
Tekit: Üsteleme.
Temerrüt: Gecikme.
Temlik (Temellük): Devretme, devralma.
Temyiz: Üst mahkeme incelemesi talebi.
Tenkis: Azaltma.
Tensip: Uygun görme.
Teraküm: Birikme, yığılma.
Tereke (Bırakıt): Ölenin aktif malvarlığı.
Teşmil: Yayma.
Tevzii (bürosu): Dağıtma (Gelen evrak ve davayı ilgili birimlere dağıtan büro).
Tutuklama: Tedbir, soruşturma veya davanın daha selim yürümesi için hürriyetin
kısıtlanmasına ilişkin karar.
Tutuklu: Tutuklanan şüpheli veya sanık.
Ücret-i vekalet: Avukatlık ücreti.
UYAP (Ulusal Yargı Ağı Projesi): Bütün adli işlemlerin elektronik ortamda
yapılarak muhafazasını sağlayan proje; bu projenin ardından ulusal
yarğı ağına verilen kısa isim.
Uzlaşma: Belirli bi edim karşılığı olarak veya olmayarak şüpheli ve mağdur
tarafın anlaşıp uzlaşması sonucu dava açılmaması veya düşmesi.
Vareste (Bağışık): Mahkeme kararı ile duruşmaya katılmama izni.
Vasıf: Suçun hangi kanun maddesini ihlal ettiğine ilişkin olan hukuki tabir;
nitelik.
Vasi: Vesayet atındakinin hukuki işlemlerini yapan, mahkeme kararı ile atanan
kişi.
Vekil: Vekalete dayalı iş yapan.
Velayet (veli): Reşit olmayan çocuğun kanuni temsilcisi, kanuna göre anne ve
baba.
Veraset (ilamı): Mirasçıları gösteren belge.
Vesayet: Vasi ile temsil edilme hali.
Yakalama emri: Çağrıldığı halde mahkemeye gelmeyen kişinin yakalanması için
çıkarılan karar.
Yargılama gideri: Soruşturma ve mahkeme aşamasında yapılan masraflar.
Yargılamanın yenilenmesi: Kesinleşen bir yargı kararının, belirli şartların
varlığında tekrar görülmesi.
Yaş tashihi: Nüfusa yanlış yazılan yaşın mahkemece düzeltilmesi.
Yazı işleri: Mahkemenin yazı işlerini yürüten birim.
Yediemin: Birden çok kişi arasında hukuki durumu çekişmeli olan bir malın,
çekişme sonuçlanıncaya kadar emanet olarak bırakıldığı kimse,
güvenilir kişi.
Yemin: Tanıkların veya tarafların doğru söylediğine ilişkin bağlayıcı metni
tekrarlamaları.
Yetki: Yasal olarak bir merciin bakabileceği işler.
Yokluk (Keenlemyekün): Hukuken işlemin sonuç doğurmaması.
Yürütmeyi durdurma: Hukuki işlemin yürümesinin engellenmesi.
Zabıt: Bir hukuki durumu tespit eden yazılı kağıt.
Zamanaşımı: Kanunda öngörülen ve belirli koşullar altında geçmekle, bir hakkın
kazanılmasını, kaybedilmesini veya bir yükümlülükten kurtulmayı
sağlayan süre.
Zımni (Kabul, ret): Üstü kapalı, açık olmayan; ima yoluyla.
Zilyet(lik): Sahibi kendisi olsun olmasın bir malı kullanmakta olan, elinde tutan
kimse. 
CUMHURİYET SAVCISININ GÖREVLERİ:
1- Adli göreve ilişkin işlem yapmak, duruşmalara katılmak ve kanun yollarına başvurmak
2-Cumhuriyet Başsavcısının verdiği idari ve adli görevleri yerine getirmek
3-Gerektiğinde Cumhuriyet Bassavcısına vekalet etmek
4-Kanunlarla verilen diğer görevleri yerine getirmek

CUMHURİYET BAŞSAVCISININ GÖREVLERİ
1-Cumhuriyet Başsavcılığını temsil etmek
2-Başsavcılığın verimli,uyumlu ve düzenli çalışmasını sağlamak, işbölümü yapmak
3-Gerektiğinde adli göreve ilişkin işlem yapmak , duruşmalara katılmak ve kanun yollarına başvurmak
4-Kanunlarla verilen diğer görevleri yerine getirmek

BAŞSAVCILIĞIN GÖREVLERİ
1-Kamu davası açılmasına yer olup olmadığına dair soruşturma yapmak veya yaptırmak
2-Kanun hükümlerince yargılama faaliyetlerini kamu adına izlemek,bunlara katılmak gerektiğinde kanun yollarına başvurmak
3-Mahkemelerce kesinleşen hükümlerin gerçekleşmesi için işlem yapmak ve izlemek
4-Kanunlarla verilen diğer görevleri yerine getirmek

HAKİMLER VE SAVCILAR YÜKSEK KURULU
*Adli ve idari hakim ve savcıları göreve kabul etme,nakletme,atama,disiplin ve terfi işlemlerini yapar
*Kurumun başkanı Adalet Bakanıdır.Adalet Bakanı Müsteşarı kurumun tabii üyesidir.
*HSYK ayrı bir tüzel kişiliğe sahip değildir.
*Cumhur Başkanı,3 asil 3 yedek Yargıtaydan,2 asil 2 yedek Danıştaydan seçer.
*Üyeleri dört yıl için seçilir
*HSYK, Danıştay üyelerinin dörtte üçünü, Yargıtay üyelerinin tamamını seçer.
*HSYK’nın kararları yargı denetiminin dışındadır.
Yazı işleri ilgisine göre Cumhuriyet Başsavcısı , mahkeme başkanı ve hakimlerin denetiminde, yazı işleri müdürünün yönetiminde zabıt katibi, memur ve mübaşirler tarafından yürütülür. İlgisine göre Cumhuriyet Başsavcısı Cumhuriyet Savcısına , Mahkeme başkanı da üyelere yazı işlerinin yürütülmesinin denetlenmesinde görev verebilir. Yazı işleri müdürü ilgisine göre C. Başsavcısı, Mahkeme Başkanı ve hakimlerin onayını alrak yönetimindeki zabıt katipleri arasında işbölümü yapabilir. yazı işlerinin gecikmesinde kalemden sorumlu zabıt katibi ve yazı işleri müdür sorumludur.
YÜKSEK MAHKEMELER
1-ANAYASA MAHKEMESİ:
*11 asil dört yedek üyeden oluşur.
* üyelerini Cumhurbaşkanı seçer.
*Başkanını kendi üyeleri arasından salt çoğunlukla seçer
*Başkan ve vekili dört yıl için seçilir.
GÖREVLERİ
-Milletvekili dokunulmazlıklarının kaldırılmasıyla ilgili itirazlara bakar.
-Kanunların,KHK (kanun hükmündeki kararnamelerin), ve Anayasa değişikliklerinin uygunluk denetimini yapar.
-Anayasa değişikliklerini sadece şekil yönünden denetler.
-Meclis iç tüzüğünü ile ilgili itirazlara bakar.
-Siyasi partilerin mali denetimini yapar.
-Siyasi partilerin kapatılma davasına bakar.
-Uyuşmazlık Mhakemesinin başkanını seçer
-Cumhurbaşkanı,Yargıtay Cumhuriyet Başsavcısı ve vekilini, Hakimler ve Savcılar yüksek kurulu başkan ve üyelerini,Sayıştay başkan ve üyelerini görevleri ile ilgili suçlardan dolayı YÜCE DİVAN sıfatıyla yargılar
Meclis başkanı ve millet vekilleri yüce divanda yargılanamaz.
2-YARGITAY:Adliye Mahkemelerince verilen karar ve hükümlerin son inceleme mercii olup ayrıca belli davalara da ilk ve son derece mahkemsi olark bakar, Yargıtay üyeleri, hakimler ve Savcılar Yüksek Kurulu üyelerince seçilir.
3-DANIŞTAY:İdare ve Vergi mahkemelerince verlien karar ve hükümlerin son inceleme mercii olup ayrıca belli davalara ilk ve son derece mahkemesi olarak bakar. Üyelerinin dörtte üçü HSYK , dörtte biri Cumhurbaşkanı tarafından seçilir.
4-ASKERİ YARGITAY:Askeri mahkemelerce verilen karar ve hükümlerin son inceleme merciidir. Üyeleri Cumhurbaşkanı tarafından seçilir.
5-ASKERİ YÜKSEK İDARE MAHKEMESİ: Asker kişileri ilgilendiren ve askeri hizmete ilişkin idari işlemlerden doğan uyuşmazlıkların yargı denetimini yapar.
6-UYUŞMAZLIK MAHKEMESİ: Adli, idari ve askeri yargı mercileri arasındaki görev ve hüküm uyuşmazlıklarını kesin olarak çözümlemeye yetkilidir. Bu mahkemenin başkanlığını Anayasa Mahkemesinin kendi üyeleri içinden görevlendirdiği üye yapar.
NOT: SAYIŞTAY VE HAKİMLER VE SAVCILAR YÜKSEK KURULU 1982 ANAYASASINDA BELİRTİLEN YÜKSEK MAHKEMELERDEN DEĞİLLERDİR . YÜKSEK SEÇİM KURULU’DA YÜKSEK MAHKEMELERDEN SAYILMAMIŞTIR.
SAYIŞTAY: TBMM adına kamu kurum ve kuruluşlarının bütün gelir ve giderlerini inceler ve denetler. SayıştayEın keisn hükümleri ahkkına ilgililer yazılı bildirim tarihinden itibaren 15 gün içinde bir kereye mahsus olmak üzere karar düzeltilmesi isteminde bulunabilirler. SayıştayEın kararlarına karşı idari yargı yoluna bşvurulmaz.
-*Danıştay kararlarıyla Sayıştay kararları çatışınsa Danıştay’ın kararları esas alınır.
-*2005 yılında yapılan Anayasa değişiklikleri ise Sayıştay merkezi yöentim bütçesi kapsamındaki kamu idareleri ile sosyal güvenlik kurumlarının bütün gelir ve giderleri ile mallarını TBMM adına denetler.
-*2005 yılında yapılan Anayasa değişiklikleri ile Mahalli idarelerin hesap ve işlemlerinin denetimi ve kesin hükme bağlanması Sayıştay tarafından yapılır
-*2004 yılında yapılan değişiklikler ile Sayıştay silahlı kuvvetlerin elinde bulunan devlet mallarının denetlemesinin yolu açılmıştır.

YÜKSEK SEÇİM KURULU
Anayasaya göre seçimler yargı organlarının genel yönetimi ve denetimi altında yapılır. Seçimlerin başlamasından bitimine kadar, seçimin düzen içinde yönetimi ve dürüstlüğüyle ilgili bütün işlemleri yapmak, seçim süresince de seçimden sonra seçimle ilgili bütün yolsuzlukları şikayet etme görevi Yüksek Seçim Kurulu’nundur. Yüksek Seçim Kurulu’nun kararları aleyhine başka bir makama başvurulamaz. Yüksek Seçim Kurulu yedi asil ve dört yedek üyeden oluşru. üyelerin 6 sı yargıtay, 5 i Danıştay genel kurullarınca kendi üyeleri arasında üye tamsayılarının salt çoğunluğunun gizli oyuyla seçilir. Yüksek Seçim Kurulu ğyelerinin görev süresi 6 yıldır. süresi biten üyeler yeniden seçilebilir. Yüksek Seçim Kurulu anayasada yasama bölümünd edüzenlenmiştir. Anayasa Mahkemesi , tıpkı sayıştay gibi Yüksek Seçim Kurulu’nu da yüksek mahkeme olarak kabul etmemiştir.
GÖREVLERİ
*İl ve ilçe seçim kurullarının oluşmasını sağlamak
* il seçim kurullarını oluşumuna, işlemlerine ve kaarlarına karşı yapılacak itirazları, oy verme gününden önce ve itiraz konusunun gerektirdiği süratle kesin karara bağlamak
*Adaylığa ait itirazlar hakkında kesin karar vermek.
*İl seçim kurullarınca düzenlenen tutanaklara karşı yapılan itirazları inceleyip kesin kara bağlamak.
*Türkiye’nin gerçeklerinden doğmuş bir düşünce sistemidir. Türk milletinin iradesiyle oluşmuş, tarihi bir gelişmenin ürünüdür. Atatürkçülük, her şeyden önce millete haklarını tanıma ve tanıtmadır; millet egemenliğinin ifadesidir. Atatürkçülük bir kurtuluştur, milletçe bağımsızlığa kavuşmadır.
*Atatürkçülük, çağdaş uygarlık seviyesine ulaşmadır, batılılaşmadır;bir diğer anlamda da modernleşmedir; hür düşünceyi temsil eder, hürriyet ve demokrasi anlayışıdır.
*Atatürkçülük, modern bir toplum hayatı yaşama demektir; laik bir düzen kurma, müspet bilim zihniyetiyle devleti yönetmedir. Bu iki anlamıyla Atatürkçülük, Türk toplumuna uygun sosyal ve siyasal kurumları kurma ve modern toplum olma demektir.
* Atatürkçülük ilkelerini “Temel İlkeler” ve “Bütünleyici İlkeler” olmak üzere iki grupta değerlendirmekteyiz. “Temel İlkeler”: Cumhuriyetçilik, Milliyetçilik, Halkçılık, Devletçilik, Laiklik ve İnkılâpçılıktır. “Bütünleyici İlkeler” ise: Milli Egemenlik, Milli Bağımsızlık, Milli Birlik ve Beraberlik, “Yurtta Sulh, Cihanda Sulh”, Çağdaşlaşma, Bilimsellik ve Akılcılık, insan ve insanlık sevgisidir.
CUMHURBAŞKANI:
Cumhurbaşkanı olabilmenin şartları nelerdir? Milletvekili olma zorunluluğu var mıdır?
Cumhurbaşkanı, Türkiye Büyük Millet Meclisince kırk yaşını doldurmuş ve yükseköğrenim yapmış kendi üyeleri veya bu niteliklere ve milletvekili seçilme yeterliğine sahip Türk vatandaşları arasından beş yıllık bir süre için seçilir. Cumhurbaşkanlığına Türkiye Büyük Millet Meclisi üyeleri dışından aday gösterilebilmesi, Meclis üye tamsayısının en az beşte birinin yazılı önerisiyle mümkündür. Cumhurbaşkanı seçilenin, varsa partisi ile ilişiği kesilir ve Türkiye Büyük Millet Meclisi Üyeliği sona erer. Cumhurbaşkanı, Türkiye Büyük Millet Meclisi üye tamsayısının üçte iki çoğunluğu ile ve gizli oyla seçilir. Türkiye Büyük Millet Meclisi toplantı halinde değilse hemen toplantıya çağrılır. Cumhurbaşkanının görev süresinin dolmasından otuz gün önce veya Cumhurbaşkanlığı makamının boşalmasından on gün sonra Cumhurbaşkanlığı seçimine başlanır ve seçime başlama tarihinden itibaren otuz gün içinde sonuçlandırılır. Bu sürenin ilk on günü içinde adayların Meclis Başkanlık Divanına bildirilmesi ve kalan yirmi gün içinde de seçimin tamamlanması gerekir. En az üçer gün ara ile yapılacak oylamaların ilk ikisinde üye tamsayısının üçte iki çoğunluk oyu sağlanamazsa üçüncü oylamaya geçilir, üçüncü oylamada üye tamsayısının salt çoğunluğunu sağlayan aday Cumhurbaşkanı seçilmiş olur. Bu oylamada üye tamsayısının salt çoğunluğu sağlanamadığı takdirde üçüncü oylamada en çok oy almış bulunan iki aday arasında dördüncü oylama yapılır, bu oylamada da üye tamsayısının salt çoğunluğu ile Cumhurbaşkanı seçilemediği takdirde derhal Türkiye Büyük Millet Meclisi seçimleri yenilenir. Seçilen yeni Cumhurbaşkanı göreve başlayıncaya kadar görev süresi dolan Cumhurbaşkanının görevi devam eder. Cumhurbaşkanı Devletin başıdır. Bu sıfatla Türkiye Cumhuriyetini ve Türk Milletinin birliğini temsil eder; Anayasanın uygulanmasını, Devlet organlarının düzenli ve uyumlu çalışmasını gözetir.
Bu amaçlarla Anayasanın ilgili maddelerinde gösterilen şartlara uyarak yapacağı görev ve kullanacağı yetkiler şunlardır:
a)	Yasama ile ilgili olanlar:
b)	Gerekli gördüğü takdirde, yasama yılının ilk günü Türkiye Büyük Millet Meclisinde açılış konuşmasını yapmak,
c)	Türkiye Büyük Millet Meclisini gerektiğinde toplantıya çağırmak,
d)	Kanunları yayımlamak,
e)	Kanunları tekrar görüşülmek üzere Türkiye Büyük Millet Meclisine geri göndermek,
f)	Anayasa değişikliklerine ilişkin kanunları gerekli gördüğü takdirde halkoyuna sunmak,
g)	Kanunların, kanun hükmündeki kararnamelerin, Türkiye Büyük Millet Meclisi İçtüzüğünün, tümünün veya belirli hükümlerinin Anayasaya şekil veya esas bakımından aykırı oldukları gerekçesi ile Anayasa Mahkemesinde iptal davası açmak,
h)	Türkiye Büyük Millet Meclisi seçimlerinin yenilenmesine karar vermek,
b) Yürütme alanına ilişkin olanlar:
Başbakanı atamak ve istifasını kabul etmek,
Başbakanın teklifi üzerine bakanları atamak ve görevlerine son vermek,
Gerekli gördüğü hallerde Bakanlar Kuruluna başkanlık etmek veya Bakanlar Kurulunu başkanlığı altında toplantıya çağırmak,
Yabancı devletlere Türk Devletinin temsilcilerini göndermek, Türkiye Cumhuriyetine gönderilecek yabancı devlet temsilcilerini kabul etmek,
Milletlerarası antlaşmaları onaylamak ve yayımlamak,
Türkiye Büyük Millet Meclisi adına Türk Silahlı Kuvvetlerinin Başkomutanlığını temsil etmek,
Türk Silahlı Kuvvetlerinin kullanılmasına karar vermek,
Genelkurmay Başkanını atamak,
Millî Güvenlik Kurulunu toplantıya çağırmak,
Millî Güvenlik Kuruluna Başkanlık etmek,
Başkanlığında toplanan Bakanlar Kurulu kararıyla sıkıyönetim veya olağanüstü hal ilân etmek ve kanun hükmünde kararname çıkarmak,
Kararnameleri imzalamak,
Sürekli hastalık, sakatlık ve kocama sebebi ile belirli kişilerin cezalarını hafifletmek veya kaldırmak,
Devlet Denetleme Kurulunun üyelerini ve Başkanını atamak,
Devlet Denetleme Kuruluna inceleme, araştırma ve denetleme yaptırtmak,
Yükseköğretim Kurulu üyelerini seçmek,
Üniversite rektörlerini seçmek,
c) Yargı ile ilgili olanlar:
Anayasa Mahkemesi üyelerini, Danıştay üyelerinin dörtte birini, Yargıtay Cumhuriyet Başsavcısı ve Yargıtay Cumhuriyet Başsavcı vekilini, Askerî Yargıtay üyelerini, Askerî Yüksek İdare Mahkemesi üyelerini, Hâkimler ve Savcılar Yüksek Kurulu üyelerini seçmek.
Cumhurbaşkanı, ayrıca Anayasada ve kanunlarda verilen seçme ve atama görevleri ile diğer görevleri yerine getirir ve yetkileri kullanır.
Sayıştay: Sayıştay, merkezi yönetim bütçesi kapsamındaki kamu idareleri ile sosyal güvenlik kurumlarının bütün gelir ve giderleri ile mallarını Türkiye Büyük Millet Meclisi adına denetlemek ve sorumluların hesap ve işlemlerini kesin hükme bağlamak ve kanunlarla verilen inceleme, denetleme ve hükme bağlama işlerini yapmakla görevlidir. Sayıştayın kesin hükümleri hakkında ilgililer yazılı bildirim tarihinden itibaren on beş gün içinde bir kereye mahsus olmak üzere karar düzeltilmesi isteminde bulunabilirler. Bu kararlar dolayısıyla idarî yargı yoluna başvurulamaz. Vergi, benzeri malî yükümlülükler ve ödevler hakkında Danıştay ile Sayıştay kararları arasındaki uyuşmazlıklarda Danıştay kararları esas alınır. Mahalli idarelerin hesap ve işlemlerinin denetimi ve kesin hükme bağlanması Sayıştay tarafından yapılır. Sayıştayın kuruluşu, işleyişi, denetim usulleri, mensuplarının nitelikleri, atanmaları, ödev ve yetkileri, hakları ve yükümlülükleri ve diğer özlük işleri, Başkan ve üyelerinin teminatı kanunla düzenlenir.
Yargıtay: Yargıtay, adliye mahkemelerince verilen ve kanunun başka bir adlî yargı merciine bırakmadığı karar ve hükümlerin son inceleme merciidir. Kanunla gösterilen belli davalara da ilk ve son derece mahkemesi olarak bakar. Yargıtay üyeleri, birinci sınıfa ayrılmış adlî yargı hâkim ve Cumhuriyet savcıları ile bu meslekten sayılanlar arasından Hâkimler ve Savcılar Yüksek Kurulunca üye tamsayısının salt çoğunluğu ile ve gizli oyla seçilir. Yargıtay Birinci Başkanı, birinci başkanvekilleri ve daire başkanları kendi üyeleri arasından Yargıtay Genel Kurulunca üye tamsayısının salt çoğunluğu ve gizli oyla dört yıl için seçilirler; süresi bitenler yeniden seçilebilirler. Yargıtay Cumhuriyet Başsavcısı ve Cumhuriyet Başsavcı vekili, Yargıtay Genel Kurulunun kendi üyeleri arasından gizli oyla belirleyeceği beşer aday arasından Cumhurbaşkanı tarafından dört yıl için seçilirler. Süresi bitenler yeniden seçilebilirler. Yargıtayın kuruluşu, işleyişi, Başkan, başkanvekilleri, daire başkanları ve üyeleri ile Cumhuriyet Başsavcısı ve Cumhuriyet Başsavcı vekilinin nitelikleri ve seçim usulleri, mahkemelerin bağımsızlığı ve hâkimlik teminatı esaslarına göre kanunla düzenlenir.
Danıştay: Danıştay, idarî mahkemelerce verilen ve kanunun başka bir idarî yargı merciine bırakmadığı karar ve hükümlerin son inceleme merciidir. Kanunla gösterilen belli davalara da ilk ve son derece mahkemesi olarak bakar. Danıştay, davaları görmek, Başbakan ve Bakanlar Kurulunca gönderilen kanun tasarıları, kamu hizmetleri ile ilgili imtiyaz şartlaşma ve sözleşmeleri hakkında iki ay içinde düşüncesini bildirmek, tüzük tasarılarını incelemek, idarî uyuşmazlıkları çözmek ve kanunla gösterilen diğer işleri yapmakla görevlidir. Danıştay üyelerinin dörtte üçü, birinci sınıf idarî yargı hâkim ve savcıları ile bu meslekten sayılanlar arasından Hâkimler ve Savcılar Yüksek Kurulu; dörtte biri, nitelikleri kanunda belirtilen görevliler arasından Cumhurbaşkanı; tarafından seçilir. Danıştay Başkanı, Başsavcı, başkanvekilleri ve daire başkanları, kendi üyeleri arasından Danıştay Genel Kurulunca üye tamsayısının salt çoğunluğu ve gizli oyla dört yıl için seçilirler. Süresi bitenler yeniden seçilebilirler. Danıştayın, kuruluşu, işleyişi, Başkan, Başsavcı, başkanvekilleri, daire başkanları ile üyelerinin nitelikleri ve seçim usulleri, idarî yargının özelliği, mahkemelerin bağımsızlığı ve hâkimlik teminatı esaslarına göre kanunla düzenlenir.
Yasama yetkisi: Yasama yetkisi Türk Milleti adına Türkiye Büyük Millet Meclisinindir. Bu yetki devredilemez.
Yürütme yetkisi ve görevi: Yürütme yetkisi ve görevi, Cumhurbaşkanı ve Bakanlar Kurulu tarafından, Anayasaya ve kanunlara uygun olarak kullanılır ve yerine getirilir.
Yargı yetkisi: Yargı yetkisi, Türk Milleti adına bağımsız mahkemelerce kullanılır.
KURTULUŞ SAVAŞI HAZIRLIK DÖNEMİ
-Mustafa Kemal in samsuna çıkması:Samsun raporunda; Bölgedeki olayların Rum çeteler tarafından çıkarıldığını İngilizlerin Samsun u haksız yere işgal ettiğini açıklamıştır.
HAVZA GENELGESİ(28 mAYIS 1919):mONDROS A KARŞI ÇIKILMIŞTIR.
Ulusal bilinç uyundurulmaya çalışılmıştır.
AMASYA GENELGESİ (22 Haziran 1919): Asıl amaç ulusal bağımsızlığı gerçekleştirmek olmasına karşın ulusal egemenlik anlayışını da içermektedir. ileride nasıl bir yönetim kurulacağının ifucudur.
ULUSUN BAĞIMSIZLIĞINI, YİNE ULUSUN AZİM VE KARARI KURTARACAKTIR.
Mondros Ateşkesine açık bir şekilde karşı çıkılmıştır.
Amasya Genelgesinden sonra 7-8 Temmuz gecesi, Mustafa Kemal görevden alındı, Mustafa Kemal de görevinden istifa etti.
ERZURUM KONGRESİ (28 TEMMUZ -7 AĞUSTOS 1919)
Temsil kurulu seçilmiştir. EN SONUMUT SONUCUDUR.
Mustafa Kemal kurtuluş Savaşında lider durumuna getirmiştir.
Meclisi Mebusanın toplanması istenmiştirn. Mustafa Kemal in sivil olarak katıldığı ilk kongredir. iki üye istifa ederek yerlerine Mustafa Kemal seçilmiştir.
TEMSİL HEYETİ: İLK defa Erzurum Kongresinde ortaya çıkmış, Sivas Kongresinde üye sayısı arttırılmıştır. TBMM açılıncaya kadar Kurtuluş Savaşını yürütmüştür. Başkanı MUSTAFA KEMAL DİR.
SİVAS KONGRESİ (4-11 EYLÜL 1919)
Erzurum Kongresi kararlarını temel olarak genişletmiştir.
Kongrenin açılmasında başkanlık ve Manda sorunu yaşamnmıştır.
Anadolu draki tüm ulusal güçler birleştirilmiştir.
Sivas Kongresinin en önemli sonuçlarından biri Damat Ferit hükümetinin istifa ettirilmesidir. Anadolu hareketinin İstanbul hükümetine karşı kazandığı ilk siyasi başarıdır.
AMASYA GÖRÜŞMELERİ (20-22 EKİM 1919)
İstanbul hükümeti, Temsil Kurulunu resmen tanımış oluyordu.
İstanbul hükümeti ve Temsil Kurulu ilk kez birlikte hareket etmişlerdir.
İkisi gizli beş protokol yapılmıştır. ancak İstanbul hükümeti seçimlerin yapılması dışında alınan kararlara uymamıştır.
-Mustafa Kemal in Ankara yı merkez seçmesi
-Son Osmanlı Mebusan Meclisinin Açılması (12 OCAK 1920)
MİSAK-I MİLLİ (ULUSAL ANT) (28 OCAK 1920)
(İSTANBUL İTİLAF DEVLETLERİ TARAFINDANRESMEN İŞGAL EDİLMİŞTİR)
(ANKARA DA TBMM AÇILMASINA NEDEN OLMUŞTUR)
-Türk yurdunun sınırları çizilmiştir.
-Kurtuluş Savaşının programı oluşmuştur.
-Sorunlara, barışçı çözüm önermiştir.
-meclis kararlarıdır. Tam bağımsızlık istenmiştir.
-Padişah onallamamıştır.
-Dünyadaki ülkelerin meclislerini duyurulması kararlaştırılmıştır.
TBMM NİN AÇILMASI (23 NİSAN 1920 )
Meclisi Mebusanın kapatılması üzerine ortaya çıkan parlamento boşluğunu doldurmak
-Ulusal bağımsızlık ve egemenliği sağlamaktır.
ALINAN İLK KARARLAR (24 NİSAN 1920)
-padişahtan bağımsız olması amaçlandı.
-Osmanlı Saltanatının yok sayılması na karar verildi.
- TBMM yasama ve yürütme yetkilerini kendinde topladı
(amaç savaş koşullarında alınacak kararların hızlandırılmasıdır. )
-Meclis Hükümeti sistemi kabul edilmiş oluyordu.
1921 ANAYASASI İLE HUKUKİ GERÇERLİLİK DE KAZANACAKTIR.
-Temsil Kurulunun görevini sona erdirmiştir.
-Hıyanet-i Vataniye Yasası çıkarıldı.
-Kurtuluş tekirdağ-yozgat
23 Mart 2009 10:41 Düzenle Sil
-Kurtuluş Savaşını yürütmüş üyeleri istiklal mahkemelerinde görev almış 23 NİSAN 1920 – 1 NİSAN 1923 tarihleri arasında görev yapmış ve saltanatı kaldırmıştır.
1.TBMM nin İlk Kanunları
—TBMM, mille mücadeleye kaynak sağlamak için küçükbaş (ağnam) hayvanlardan alınan vergiyi artırmıştır. Bunun yanında Hıyaneti Vataniye kanununu çıkarılarak otoritesi güçlendirilmiştir. Kanunu gevrekçesi asker kaçaklarının artmaksı ve ayaklanmaların çıkmasıdır.
Firariler hakkında kunun çıkarılarak askerden kaçanları yargılamak üzere istiklal Mahkemeleri kurulmuştur.
SEVR BARIŞ ANTLAŞMASI (10 Ağustos 1920)
-Osmanlı Parlamentosunda onaylanmadığından hukuken geçersizdir.
- Kurtuluş Savaşı kazanıldığı için uygulanmamıştır.
-TBMM antlaşmayı tanımadığı gibi imzalayanları da vatan haini ilan etmiştir.
-Antlaşmanın amaıcı Türk ulusuna son vermekti. Bu durum ise Türk ulusunun bağımsızlık mücadelesini hızlandıracaktır.
(BATILI DEVLETLERİN OSMANLI Devletini nasıl paylaşacakları tartışmasının uzaması diğer antlaşmalara göre daha geç imzalanmasına neden olmuştur.)

MUHAREBELER DÖNEMİ
DOĞU CEPHESİ
GÜNEY CEPHESİ
BATI CEPHESİ
DOĞU CEPHESİ:
-TBMM NİN AÇTIĞI İLK CEPHEDİR.
-eRMENİ VE gÜRCÜLER 1. Dünya savaşı bunulımından yararlanarak;Kars, Ardahan ve Batum u işgal etmişlerdi.
(Türk ordusunun başarısı ile GÜMRÜ BARIŞI YAPILMIŞTIR..”ERMENİLERLE”)
_Kars ve çevresi Türklere geri verildi.
-Ermenistan Misak ı Milliyi tanıdı.
-TBMM Yİ tanıyan ve Sevr den vazgeçen ilk devlet Ermenistan dır
-TBMM nin imzaladığı ilk anlaşmadır.
(TBMM NİN ULUSLARARASI ALANDA İLK BAŞARISIDIR)
GÜNEY CEPHESİ:(FRANSA İLE ANKARA ANTLAŞMASI 20 EKİM 1921 İLE SONA ERMİŞ VE GÜNEY SINIRI ÇİZİLMİŞTİR.
BATI CEPHESİ: TBMM nin kurduğu düzenli ordu savaşmıştır.
yunanlılara karşı açılmıştır
En büyük maharebeler burda verilmiştir. bu muharebeler 1. ve 2. inönü savaşları, kütahya, eskişehir savaşları, Sakarya Meydan Savaşı ve Büyük Taarruz dur..
1. İNÖNÜ SAVAŞI (6-10 OCAK 1921 )
SAVAŞI TBMM ordusu kazanmıştır
-yeni kuruluna düzenli ordunun ilk başarısıdır.
-Halkın TBMM ye olan güveni artmıştır.
- Savaş sonrasi ilk Anayasa kabul edildi. (20 ocak 1921)
-iSTİKLAL marşı kabul edildi.
-İtilaf devletleri LONDRO KONFERANSINI TOPLADI
LONDRA KONFERANSI (21 Şubat -12 Mart 1921)
amaç; servi değiştirip TBMM ye kabul ettirmektir
-TBMM İSE mİSAK I mİLLİ Yİ DÜNYA KAMU OYUNA KABUL ETTİRMEK İÇİN KATILDI.
-iTİLAF DEVLETLERİ tbmm yi ilk kez resmen tanımış oldular.
MOSKOVA ANTLAŞMASI(16 Mart 1921)
-Sovyet Rusya ile imzalandı.
-Her iki devlet eski anlaşmaları geçersiz saydı
BÖYLECE SOVYET RUSYA KAPİTÜLASYON HAKKINDAN İLK VAZGEÇEN DEVLET OLDU.
-Misak ı Milli yi ilk tanıyan büyük devlet oldu.
-Batum ilk taviz verildi
-doğu sınırı güvence altına alındı.
2. İNÖNÜ SAVAŞI 822-31 MART 1921 )
Yunanlıların 1. inönü mağlubiyetinin izlerini silmek istemesi
ESKİŞEHİR KÜTAHYA SAVAŞLARI (10 -24 TEMMUZ 1921)
_TBMM ordusu sakarya nehrinin doğusuna çekildi.
-Mustafa Kemal Başkomutanlığa g2etirildi
- Tekalif i Milliye Yasası çıkarıldı.
Başkomutanlık Kanunu:Mustafa kemal in ordunun başına geniş yetkilerle geçmesi olarak belirlenmiştir.
TEKALİF İ MİLLİYE EMİRLERİ
-SAKARYA SAVAŞI ( 23 AĞUSTOS-12EYLÜL 1921)
-Yunanlıların son saldırı savaşı oldu.
-mUSTAFA K. E gazilik ve Mareşallik rütbesi verildi.
-Kars antlaşması imzalandı.
-Ankara Antlaşması imzalandı
-Türklerin geri çekilişi sona erdi.
KARS ANTLAŞMASI
-Sakarya savaşxından sonra imzalanmıştır
-TBMM İLE sovyet Rusya, denetimi altındoa
-Dostluk antlaşmasıdır
-Doğu sınırı kesinleşmiştir
ANKARA ANTLAŞMASI ( 20 Ekim 1921)
“TBMM Yİ TANIYAN İLK İTİLAF DEVLETİ fRANSA OLMUŞTUR”


ATATÜRK’ÜN KENDİ İFADESİYLE İLKELERİNİN TANIMI
I.TEMEL İLKELER
1-Cumhuriyetçilik
-Türk milletinin karakter ve adetlerine en uygun olan idare, Cumhuriyet idaresidir.(1924)
-Cumhuriyet rejimi demek, demokrasi sistemiyle devlet şekli demektir. (1933)
-Cumhuriyet, yüksek ahlaki değer ve niteliklere dayanan bir idaredir. Cumhuriyet fazilettir… (1925)
-Bugünkü hükümetimiz, devlet teşkilatımız doğrudan doğruya milletin kendi kendine, kendiliğinden yaptığı bir devlet ve hükümet teşkilatıdır ki, onun adı cumhuriyet’tir. Artık hükümet ile millet arasında geçmişteki ayrılık kalmamıştır. Hükümet millet ve millet hükümettir. (1925)
2-Milliyetçilik:
-Türkiye Cumhuriyeti’ni kuran Türk halkına Türk Milleti denir. (1930)
-Diyarbakırlı, Vanlı, Erzurumlu, Trakyalı, hep bir soyun evlatları ve aynı cevherin damarlarıdır. (1923)
-Biz doğrudan doğruya milliyetperveriz ve Türk milliyetçisiyiz. Cumhuriyetimizin dayanağı Türk toplumudur. Bu toplumun fertleri ne kadar Türk kültürüyle dolu olursa, o topluma dayanan Cumhuriyet de o kadar kuvvetli olur. (1923)
3-Halkçılık:
-İç siyasetimizde ilkemiz olan halkçılık, yani milletin bizzat kendi geleceğine sahip olması esası Anayasamızla tespit edilmiştir. (1921)
-Halkçılık, toplum düzenini çalışmaya, hukuka dayandırmak isteyen bir toplum sistemidir. (1921)
-Türkiye Cumhuriyeti halkını ayrı ayrı sınıflardan oluşmuş değil, fakat kişisel ve sosyal hayat için işbölümü itibariyle çeşitli mesleklere ayrılmış bir toplum olarak görmek esas prensiplerimizdendir. (1923)
4-Devletçilik:
-Devletçiliğin bizce anlamı şudur: kişilerin özel teşebbüslerini ve şahsi faaliyetlerini esas tutmak, fakat büyük bir milletin ve geniş bir memleketin ihtiyaçlarını ve çok şeylerin yapılmadığını göz önünde tutarak, memleket ekonomisini devletin eline almak. (1936)
-Prensip olarak, devlet ferdin yerine geçmemelidir. Fakat ferdin gelişmesi için genel şartları göz önünde bulundurmalıdır. (1930)
-Kesin zaruret olmadıkça, piyasalara karışılmaz; bununla beraber, hiçbir piyasa da başıboş değildir. (1937)
5-Laiklik:
-Laiklik, yalnız din ve dünya işlerinin ayrılması demek değildir. Bütün yurttaşların vicdan, ibadet ve din hürriyeti de demektir. (1930)
-Laiklik, asla dinsizlik olmadığı gibi, sahte dindarlık ve büyücülükle mücadele kapısını açtığı için, gerçek dindarlığın gelişmesi imkânını temin etmiştir. (1930)
-Din bir vicdan meselesidir. Herkes vicdanının emrine uymakta serbesttir. Biz dine saygı gösteririz. Düşünüşe ve düşünceye karşı değiliz. Biz sadece din işlerini, millet ve devlet işleriyle karıştırmamaya çalışıyor, kasıt ve fiile dayanan tutucu hareketlerden sakınıyoruz. (1926)
6-İnkılâpçılık:
-Yaptığımız ve yapmakta olduğumuz inkılâpların gayesi Türkiye Cumhuriyeti halkını tamamen çağdaş ve bütün anlam ve görüşleriyle medeni bir toplum haline ulaştırmaktır. (1925)
-Biz büyük bir inkılâp yaptık. Memleketi bir çağdan alıp yeni bir çağa götürdük. (1925)
II- BÜTÜNLEYİCİ İLKELER
1-Milli Egemenlik:
- Yeni Türkiye devletinin yapısının ruhu milli egemenliktir; milletin kayıtsız şartsız egemenliğidir. Toplumda en yüksek hürriyetin, en yüksek eşitliğin ve adaletin sağlanması, istikrarı ve korunması ancak ve ancak tam ve kesin anlamıyla milli egemenliği sağlamış bulunmasıyla devamlılık kazanır. Bundan dolayı hürriyetin de, eşitliğin de, adaletin de dayanak noktası milli egemenliktir. (1923)
2-Milli Bağımsızlık:
-Tam bağımsızlık denildiği zaman, elbette siyasi, mali, iktisadi, adli, askeri, kültürel ve benzeri her hususta tam bağımsızlık ve tam serbestlik demektir. Bu saydıklarımın herhangi birinde bağımsızlıktan mahrumiyet, millet ve memleketin gerçek anlamıyla bütün bağımsızlığından mahrumiyeti demektir. (1921)
-Türkiye devletinin bağımsızlığı mukaddestir. O ebediyen sağlanmış ve korunmuş olmalıdır. (1923)
3-Milli Birlik ve Beraberlik:
- Millet ve biz yok, birlik halinde millet var. Biz ve millet ayrı ayrı şeyler değiliz. (1919)
Biz milli varlığın temelini, milli şuurda ve milli birlikte görmekteyiz. (1936)
Toplu bir milleti istila etmek, daima dağınık bir milleti istila etmek gibi kolay değildir. (1919)
4-Yurtta Sulh (Barış), Cihanda Sulh:
-Yurtta sulh, cihanda sulh için çalışıyoruz. (1931)
-Türkiye Cumhuriyeti’nin en esaslı prensiplerinden biri olan yurtta sulh, cihanda sulh gayesi, insaniyetin ve medeniyetin refah ve telakisinde en esaslı amil olsa gerekir. (1919)
-Sulh milletleri refah ve saadete eriştiren en iyi yoldur. (1938)
5-Çağdaşlaşma:
-Milletimizi en kısa yoldan medeniyetin nimetlerine kavuşturmaya, mesut ve müreffeh kılmaya çalışacağız ve bunu yapmaya mecburuz. (1925)
-Biz batı medeniyetini bir taklitçilik yapalım diye almıyoruz. Onda iyi olarak gördüklerimizi, kendi bünyemize uygun bulduğumuz için, dünya medeniyet seviyesi içinde benimsiyoruz. (1926)
6-Bilimsellik ve Akılcılık:
a) Bilimsellik: Dünyada her şey için, medeniyet için, hayat için, başarı için en gerçek yol gösterici bilimdir, fendir. (1924)
Türk milletinin yürümekte olduğu ilerleme ve medeniyet yolunda, elinde ve kafasında tuttuğu meşale, müspet bilimdir. (1933)
b) Akılcılık: Bizim, alık, mantık, zekâyla hareket etmek en belirgin özelliğimizdir. (1925)
Bu dünyada her şey insan kafasından çıkar. (1926)
7-İnsan ve İnsanlık Sevgisi:
-İnsanları mesut edeceğim diye onları birbirine boğazlatmak insanlıktan uzak ve son derece üzülünecek bir sistemdir. İnsanları mesut edecek yegâne vasıta, onları birbirlerine yaklaştırarak, onlara birbirlerini sevdirerek, karşılıklı maddi ve manevi ihtiyaçlarını temine yarayan hareket ve enerjidir. (1931)
-Biz kimsenin düşmanı değiliz. Yalnız insanlığın düşmanı olanların düşmanıyız. (1936)

ATATÜRK İNKILAPLARI (DEVRİMLERİ)
I-Siyasi alanda yapılan inkılâplar:
1- Saltanatın Kaldırılması (1 Kasım 1922)
2- Cumhuriyet’in ilanı (29 Ekim 1923)
3- Halifeliğin Kaldırılması (3 Mart 1924)
II-Toplumsal yaşayışın düzenlenmesi:
1- Şapka İktisası (giyilmesi) Hakkında Kanun (25 Kasım 1925)
2- Tekke ve Zaviyelerle Türbelerin Seddine (kapatılmasına) ve Türbedarlıklar ile Birtakım Unvanların Men ve İlgasına Dair Kanun (30 Kasım 1925)
3- Beynelmilel Saat ve Takvim Hakkındaki Kanunların Kabulü (26 Aralık 1925). Kabul edilen bu kanunlarla Hicri ve Rumi Takvim uygulaması kaldırılarak yerine Miladi Takvim, alaturka saat yerine de milletlerarası saat sistemi uygulaması benimsenmiştir.
4- Ölçüler Kanunu (1 Nisan 1931). Bu kanunla ölçü birimi olarak medeni milletlerin kullandıkları metre, kilogram ve litre kabul edilmiştir.
5- Lakap ve Unvanların Kaldırıldığına Dair Kanun (26 Kasım 1934)
6- Bazı Kisvelerin Giyilemeyeceğine Dair Kanun (3 Aralık 1934). Bu kanunla din adamlarının, hangi dine mensup olurlarsa olsunlar, mabet ve ayinler dışında ruhani kisve (giysi) taşımaları yasaklanmıştır.
7- Soyadı Kanunu (21 Haziren 1934)
8- Kemal Öz Adlı Cumhur reisimize Atatürk Soyadı Verilmesi Hakkında Kanun (24 Kasım 1934)
9- Kadınların medeni ve siyasi haklara kavuşması:
a- Medeni Kanun’la sağlanan haklar
b- Belediye seçimlerinde kadınlara seçme ve seçilme hakkı tanıyan kanunun kabulü (3 Nisan 1930)
c- Anayasa’da yapılan değişiklerle kadınlara milletvekili seçme ve seçilme hakkının tanınması (5 Aralık 1934)
III- Hukuk alanında yapılan inkılâplar:
1- Şeriye Mahkemelerinin kaldırılması ve Yeni Mahkemeler Teşkilatının Kurulması Kanunu (8 Nisan 1934)
2- Türk Medeni Kanunu (17 Şubat 1926)
Dini hukuk sisteminden ayrılarak laik çağdaş hukuk sisteminin uygulanmasına başlanmıştır.
IV-Eğitim ve Kültür alanında yapılan inkılâplar:
1- Tevhid-i Tedrisat Kanunu (3 Mart 1924). Bu kanunla Türkiye dahilindeki bütün bilim ve öğretim kurumları Milli Eğitim Bakanlığı’na bağlanmıştır.
2- Yeni Türk Harflerinin Kabul ve Tatbiki Hakkında Kanun (1 Kasım 1928)
3- Türk Tarihi Tetkik Cemiyeti’nin Kuruluşu (12 Nisan 1931). Cemiyet daha sonra Türk Tarih Kurumu adını almıştır (3 Ekim 1935). Kültür alanında yeni bir tarih görünüşünü ifade eden kurumun kuruluşuyla ümmet tarihi anlayışından millet tarihi anlayışına geçilmiştir.
4- Türk Dili Tetkik Cemiyeti’nin kuruluşu (12 Temmuz 1932). Cemiyet daha sonra Türk Dil Kurumu adını almıştır (24 Ağustos 1936). Kurumun amacı, Türk dilinin öz güzelliğini ve zenginliğini meydana çıkarmak, onu dünya dilleri arasında değerine yaraşır yüksekliğe eriştirmektir.
5- İstanbul Darülfünunu’nun kapatılmasına Milli Eğitim Bakanlığı’nca yeni bir üniversite kurulmasına dair kanun (31 Mayıs 1933). İstanbul Üniversitesi 18 Kasım 1933 günü öğretime açılmıştır
Türkiye’nin komşuları – Başkentleri: 

Ülkemizin sınırları itibariyle sekiz komşu ülkesi bulunmaktadır. 8333 kmlik sahil uzunluğuna sahip olan ülkemizde komşu ülke olarak en uzun sınırımız Suriye, en kısa sınırımız ise Nahcivan iledir.

turkiyenin komsulari Türkiyenin Komşuları Hangileridir? Türkiyenin Komşu Ülkeleri
Doğu komşuları

Gürcistan: Türkiye ile ekonomik ilişkiler içinde de bulunan Gürcistan, Türkiye’den hem ithalat yapmakta hem de ihracat yapmaktadır. Başkenti Tiflis’tir.

Ermenistan: SSCB’ye bağlı iken bu birliğin 1991 yılında dağılmasıyla bağımsızlığını kazanan Ermenistan’ın başkenti Erivan’dır. Azerbaycan’a ait bir bölge olarak kabul edilmiş olan Dağlık Karabağ bölgesinin %20′sini işgal etmesinden dolayı Türkiye, bu ülke ile sınırlarını kapatmıştır.

Nahcivan: iç işlerinde özerk, dış işlerinde ise Azerbaycan’a bağlı bir bölge olan ülkenin başkenti de Nahcıvan’dır

İran: Türkiye’nin komşuları arasında, yüzölçümü Türkiye’den büyük olan tek ülke olan İran’ın başkenti Tahran.
Güneydoğu komşusu

Irak: petrol zenginliği ve tarıma elverişliliği nedeniyle oldukça jeopolitik bir öneme sahip olan Irak, İran’dan sonra yüzölçümü en geniş ülkedir. Başkenti ise Bağdat’tır.
Güney komşusu

Suriye: başkenti Şam
Batı komşuları

Bulgaristan; başkenti Sofya

Yunanistan; başkenti Atina

COĞRAFYA
İç Anadolu Bölgesi:
Dağları: Karacadağ, Melendiz, Hasandağı, Erciyes, Tahtalı, Tecer, Yıldız, Ak Dağları, Sundiken ve Sivrihisar Dağları
Platoları: Haymana, Cihanbeyli, Obruk
Gölleri: Tuz, Eber, Akşehir, Çavuşçu, Seyfe, Sultan sazlığı, Tuzla ve Acıgöl
Akarsuları: Kızılırmak, Delice Çayı, Çekerek Suyu, Ankara Çayı, Porsuk Çayı
Tarım Ürünleri: buğday, arpa, yulaf, şeker pancarı, baklagiller, patates, elma
Yeraltı Zenginlikleri: florid , krom, linyit, bakır, çinko, kurşun, manganez, jips, mika, lületaşı
Karadeniz Bölgesi:
Dağları: Ilgaz, Canik, Bolu, Köroğlu, Yalnızçam, Çimen, Mescit, Küre, Bolu ve Doğu Karadeniz Dağları
Ovaları: Çarşamba, Bafra
Gölleri: Tortum, Abant Yedi Göller, Borabay, Sera
Tarım Ürünleri: Fındık, çay, mısır, tütün, şeker pancarı, keten, kenevir, fasulye, pirinç, buğday, çeltik
Yeraltı Zenginlikleri: bakır, maden kömürü, linyit
Marmara Bölgesi:
Dağları: Yıldız, Koru, Biga, Kaz, Kapı, Işıklar, Uludağ
Tarım Ürünleri: ayçiçeği, buğday, tütün, şeker pancarı, pamuk, mısır, fındık, zeytin, pirinç patates,
Yeraltı Zenginlikleri:
Önemli Tarihi Yerleri: Dolmabahçe Sarayı, Topkapı Sarayı, Resim ve Heykel Müzesi, Güzel Sanatlar Galerisi, Deniz Müzesi, Askeri Müze, Ayasofya, Yerebatan Sarayı, Su kemerleri, Anadolu ve Rumeli Hisarları, Galata Kulesi, Sultanahmet Camii, Süleymaniye Camii, Boğaziçi ve Fatih Sultan Mehmet Köprüleri
Doğu Anadolu Bölgesi:
Dağları: Mercan, Nemrut, Süphan, Buzul, Ağrı, Aladağ, Tendürek
Ovaları: Yüksekova
Gölleri: Van gölü,
Akarsuları: Fırat, Dicle, Aras, Büyük Zap, Kura Ceyhan
Tarım Ürünleri: buğday, arpa, yulaf, baklagiller, şeker pancarı, tütün, pamuk çeşitleri,
Yeraltı Zenginlikleri: demir, bakır, kurşun, çinko, gümüş, krom, linyit
Ege Bölgesi:
Dağları: Aydın Dağları, Bozdağlar, Dumlu Dağı, Yunt Dağı, Madra Dağı, Kaz Dağı, Eğrigöz Dağı, Türkmen Dağı, Şaphane Dağı, Sandıklı Dağları
Ovaları: Büyük ve Küçük Menderes Ovaları, Gediz Ovası ve Bakırçay Ovası
Körfezleri: Edremit, Çandarlı, İzmir, Kuşadası, Güllük, Gökova
Akarsuları: Büyük ve Küçük Menderes, Bakırçay, Simav (Susurluk), Gediz, Porsuk
Barajları: Adıgüzel, Kemer, Gediz, Demirköprü
Tarım Ürünleri: Çekirdeksiz üzüm, turunçgil, mısır, incir, zeytin, haşhaş, şeker pancarı ve buğday
Yeraltı Zenginlikleri: Linyit, zımpara taşı, cıva, demir, krom
Akdeniz Bölgesi:
Dağları: Toros Dağları, Amanos Dağları (Nur Dağları), Tahtalı Dağları, Bey Dağları, Akdağlar, Çiçekbaba Dağları, Sultan Dağları, Geyik Dağları, Bolkar Dağları, Binboğa Dağları
Ovaları: Çukurova, Silifke, Antalya, Finike, Fethiye, Köyceğiz, Amik(Hatay), Sağlık(Türkoğlu- Kahramanmaraş), Acıpayam(Denizli), Isparta ve Burdur Ovları, Elmalı, Kestel, Korkuteli
Gölleri: Beyşehir, Eğirdir, Burdur, Acıgöl, Kestel, Avlan, Suğla, Salda ve Söğüt
Akarsuları: Dalaman, Kocaçay(Eşen Çayı), Derme, Alakır, Aksu, Köprü ve Manavgat Çayları, Göksu Nehri, Tarsus Çayı, Seyhan, Ceyhan ve Asi Nehirleri
Geçitleri: Belen ( İskenderun – Antakya), Gülek ( Adana – Ulukışla – Ankara), Sertavul ( Silifke – Karaman) ve Çubuk ( Antalya – Göller yöresi)
Tarım Ürünleri: buğday, pamuk, zeytin, turunçgil, mısır, yer fıstığı, susam, anason, baklagiller, gül, şeker pancarı, haşhaş, soya fasulyesi, üzüm, elma, erik, muz, çilek
Yeraltı Zenginlikleri: Krom, boksit, demir, linyit,
Güneydoğu Anadolu Bölgesi:
Dağları:
Ovaları: Altınbaşak, Suruç, Gaziantep, Barak, Adıyaman, Şanlı Urfa, Harran, Ceylanpınar
Gölleri: Azaplı, İnekli, Gölbaşı
Barajları: Devegeçidi, Dicle, Batman
Tarım Ürünleri: tahıl, baklagil, pamuk, susam, ayçiçeği, Antep fıstığı, buğday, kırımızı mercimek, nohut, tütün, üzüm, zeytin
Yeraltı Zenginlikleri: Fosfat, petrol, çimento


Online İKM Mülakatı:www.katipler.net/mulakat
', NULL, NULL, N'~/Style/folder.png', 1, '20140510')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (15, 13, 28, N'İki bilinmeyenli denklemler', 1, NULL, NULL, NULL, N'~/Style/folder.png', 1, '20140510')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (16, NULL, 28, N'Yeni Üst İçerik', 1, N'', NULL, NULL, N'~/Style/ArsivAna.png', 1, '20140511 17:40:58.543')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (17, 16, 28, N'Ust İçerik Altı', 1, N'aman aman', NULL, NULL, N'~/Style/folder.png', 1, '20140511 17:41:20.407')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (18, NULL, 30, N'Test Pdf', 2, NULL, N'/Dokumanlar/OmerFarukOcakoglu/ödev 3.pdf', NULL, N'~/Style/ArsivAna.png', 1, '20140511 19:01:29.993')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (19, 18, 30, N'içerik denemesi', 1, N'<p class="MsoNormal"><strong><span style="text-decoration: underline;">2013 Yılı G&uuml;ncel
Bakanlar Listesi:</span></strong></p>
<p class="MsoNormal"><strong><span style="text-decoration: none;">&nbsp;</span></strong></p>
<p class="MsoNormal">Adalet Bakanı: Sadullah Ergin</p>
<p class="MsoNormal">Dış İşleri Bakanı: Ahmet Davutoğlu</p>
<p class="MsoNormal">Maliye Bakanı: Mehmet Şimşek</p>
<p class="MsoNormal">&Ccedil;alışma ve Sosyal G&uuml;venlik Bakanı: Faruk &Ccedil;elik</p>
<p class="MsoNormal">Enerji ve Tabii Kaynaklar Bakanı: Taner Yıldız</p>
<p class="MsoNormal">Gıda Tarım ve Hayvancılık Bakanı: Mehmet Mehdi Eker</p>
<p class="MsoNormal">Gen&ccedil;lik ve Spor Bakanı: Suat Kılı&ccedil;</p>
<p class="MsoNormal">Milli Savunma Bakanı: İsmet Yılmaz</p>
<p class="MsoNormal">G&uuml;mr&uuml;k ve Ticaret Bakanı: Hayati Yazıcı</p>
<p class="MsoNormal">K&uuml;lt&uuml;r ve Turizm Bakanı: &Ouml;mer &Ccedil;elik</p>
<p class="MsoNormal">Kalkınma Bakanı: Cevdet Yılmaz</p>
<p class="MsoNormal">Ekonomi Bakanı: Mehmet Zafer &Ccedil;ağlayan</p>
<p class="MsoNormal">Ulaştırma Denizcilik ve Haberleşme Bakanı: Binali Yıldırım</p>
<p class="MsoNormal">&Ccedil;evre ve Şehircilik Bakanı: Erdoğan Bayraktar</p>
<p class="MsoNormal">Milli Eğitim Bakanı: Nabi Avcı</p>
<p class="MsoNormal">Sağlık Bakanı: Mehmet M&uuml;ezzinoğlu</p>
<p class="MsoNormal">Orman ve Su İşleri Bakanı: Veysel Eroğlu</p>
<p class="MsoNormal">Bilim Sanayi ve Teknoloji Bakanı: Nihat Erg&uuml;n</p>
<p class="MsoNormal">Avrupa Birliği Bakanı: Egemen Bağış</p>
<p class="MsoNormal">Aile ve Sosyal Politikalar Bakanı: Fatma Şahin</p>
<p class="MsoNormal">İ&ccedil;işleri Bakanı: Muammer G&uuml;ler</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal"><strong><span style="text-decoration: underline;">Cumhurbaşkanları
Listesi:</span></strong></p>
<p class="MsoNormal" style="margin-left: 18pt; text-indent: -18pt;">1.<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Mustafa Kemal Atat&uuml;rk: 29 Ekim 1923 &ndash; 10 Kasım 1938 (4
d&ouml;nem, CHP)</p>
<p class="MsoNormal" style="margin-left: 18pt; text-indent: -18pt;">2.<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>İsmet İn&ouml;n&uuml;: 11 Kasım 1938 &ndash; 22 Mayıs 1950 (4 d&ouml;nem,
CHP)</p>
<p class="MsoNormal" style="margin-left: 18pt; text-indent: -18pt;">3.<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Celal Bayar: 22 Mayıs 1950 &ndash; 1 Kasım 1960 (3 d&ouml;nem,
Demokrat Parti)</p>
<p class="MsoNormal" style="margin-left: 18pt; text-indent: -18pt;">4.<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Cemal G&uuml;rsel: 27 Mayıs 1960 &ndash; 28 Mart 1966 (2 d&ouml;nem,
Bağımsız)</p>
<p class="MsoNormal" style="margin-left: 18pt; text-indent: -18pt;">5.<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Cevdet Sunay: 28 Mart 1966 &ndash; 28 Mart 1973 (1 d&ouml;nem,
Bağımsız)</p>
<p class="MsoNormal" style="margin-left: 18pt; text-indent: -18pt;">6.<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Fahri Korut&uuml;rk: 6 Nisan 1973 &ndash; 6 Nisan 1980 (1 d&ouml;nem,
Bağımsız)</p>
<p class="MsoNormal" style="margin-left: 18pt; text-indent: -18pt;">7.<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Kenan Evren: 9 Kasım 1982 &ndash; 9 Kasım 1989 (1 d&ouml;nem,
Bağımsız)</p>
<p class="MsoNormal" style="margin-left: 18pt; text-indent: -18pt;">8.<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>Turgut &Ouml;zal: 31 Ekim 1989 &ndash; 17 Nisan 1993 (1 d&ouml;nem,
Anavatan Partisi)</p>
<p class="MsoNormal" style="margin-left: 18pt; text-indent: -18pt;">9.<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span>S&uuml;leyman Demirel: 16 Mayıs 1993 &ndash; 16 Mayıs 2000 (1
d&ouml;nem, Doğru Yol Partisi)</p>
<p class="MsoNormal" style="margin-left: 18pt; text-indent: -18pt;">10.<span style="font-size: 7pt;">&nbsp; </span>Ahmet
Necdet Sezer: 16 Mayıs 2000 &ndash; 28 Ağustos 2007 (1 d&ouml;nem, Bağımsız)</p>
<p class="MsoNormal" style="margin-left: 18pt; text-indent: -18pt;">11.<span style="font-size: 7pt;">&nbsp; </span>Abdullah
G&uuml;l: 28 Ağustos 2007 &ndash; Halen g&ouml;revde (Adalet ve Kalkınma Partisi)</p>
<p><strong><span style="text-decoration: underline;">D&uuml;nyanın 7 harikası:</span></strong><span style="text-decoration: underline;"></span></p>
<p>1-Kurtarıcı İsa Heykeli &ndash; Brezilya<br />
2-Manchu Pichu Şehri &ndash; Peru<br />
3- Tac Mahal &ndash; Hindistan<br />
4-Chicken İtza Piramidi &ndash; Meksika<br />
5- &Ccedil;in Seddi &ndash; &Ccedil;in<br />
6- Petra Antik Kenti &ndash; &Uuml;rd&uuml;n<br />
7- Colisseum &ndash; İtalya</p>
<p class="MsoNormal" style="text-align: center;">Online İKM M&uuml;lakatı:<span style="text-decoration: underline;">www.katipler.net/mulakat</span></p>
<p><strong><span style="text-decoration: underline;">Avrupa Başkentleri:</span></strong></p>
<p>Almanya : Berlin<br />
Andorra : Andorra La
Vella<br />
Arnavutluk : Tiran<br />
Avusturya : Viyana<br />
Belarus : Minsk<br />
Bel&ccedil;ika : Br&uuml;ksel<br />
Bosna ve Hersek : Saraybosna<br />
Bulgaristan : Sofya<br />
BBritanya ve Kİrlanda : Londra<br />
&Ccedil;ek Cumhuriyeti : Prag<br />
Danimarka : Kopenhang<br />
Estonya : Tailin<br />
Finlandia : Helsinki<br />
Fransa : Paris<br />
Hırvatistan : Zagrep<br />
Hollanda : Amsterdam<br />
İrlanda Cumhuriyeti : Dublin<br />
İspanya : Madrid<br />
İsve&ccedil; : Stockholm<br />
İsvi&ccedil;re : Bern<br />
İtalya : Roma<br />
İzlanda : Reykjavik<br />
KKTC : Lefkoşe<br />
GKRY : Nicosia<br />
Lettonya : Riga<br />
Liechtenstein Prensliği : Vaduz<br />
Litvanya : Vilnus<br />
L&uuml;ksemburg : L&uuml;ksemburg<br />
Macaristan : Budapeşte<br />
Makedonya : &Uuml;sk&uuml;p<br />
Malta : Valletta<br />
Moldova : Kişinev<br />
Monako : Monako<br />
Norve&ccedil; : Oslo<br />
Polonya : Varşova<br />
Portekiz : Lizbon<br />
Romanya : B&uuml;kreş<br />
Rusya Federasyonu : Moskova<br />
San Marino Cumhuriyeti : San Marino<br />
Sırbistan-Karadağ : Belgrad<br />
Slovakya : Bratislava<br />
Slovenya : Ljubljana<br />
T&uuml;rkiye : Ankara<br />
Ukrayna : Kiev<br />
Yunanistan : Atina</p>
<p class="MsoNormal" style="text-align: center;">Online İKM M&uuml;lakatı:<span style="text-decoration: underline;">www.katipler.net/mulakat</span></p>
<p class="MsoNormal" style="text-align: center;"><span style="text-decoration: underline;">&nbsp;</span></p>
<p class="MsoNormal" style="text-align: center;">&nbsp;</p>
<p>&nbsp;</p>
<p><strong><span style="text-decoration: underline;">T&uuml;rkiye&rsquo;nin enleri ve ilkleri</span></strong>:</p>
<p >
-İlk hava şehidimiz Fethi Bey&rsquo;dir.<br />
-İlk T&uuml;rk u&ccedil;ağı Mavi Işık&rsquo;tır(Kayseri/1979)<br />
-D&uuml;nyanın ilk ve tek cellat mezarı İstanbul Ey&uuml;p&rsquo;te yer alır.<br />
-Nargile Osmanlı&rsquo;ya ilk olarak Yavuz Sultan Selim zamanında Hindistan&rsquo;dan
getirildi.<br />
-Yerleşim yerine yapılan ilk baraj Denizli G&ouml;kpınar Barajı&rsquo;dır.<br />
-T&uuml;rkiye&rsquo;de ilk n&uuml;fus sayimi 1927 yılında yapıldı.<br />
-En fazla yağış alan ilimiz Rize&rsquo;dir.<br />
-TBMM&rsquo;nin ilk baskani Fethi Okyar&rsquo;dir.<br />
-Ilk basbakanimiz Ismet In&ouml;n&uuml;&rsquo;d&uuml;r.<br />
-En b&uuml;y&uuml;k adamiz G&ouml;k&ccedil;eada&rsquo;dir.(&Ccedil;anakkale)<br />
-Ingilizce ile egitime baslayan ilk T&uuml;rk okulu Ankara TED Koleji&rsquo;dir.(1954)<br />
-T&uuml;rkiye&rsquo;de &ouml;z&uuml;rl&uuml;lere y&ouml;nelik ilk otel Antalya&rsquo;da hizmete girmiştir<br />
-T&uuml;rkiye&rsquo;nin ilk &ouml;zel hayvanat bah&ccedil;esi Bogazi&ccedil;i Hayvanat
Bah&ccedil;esi&rsquo;dir.(Izmit-Darica)<br />
-T&uuml;rkiye Cumhuriyeti&rsquo;nin ilk anayasası 1924 anayasasıdır.<br />
-T&uuml;rkiye&rsquo;nin en &ccedil;ok otel bulunan yeri Emin&ouml;n&uuml;&rsquo;d&uuml;r.<br />
-T&uuml;rkiye&rsquo;de feribot ile taşımacılık yapılan tek g&ouml;l Van G&ouml;l&uuml;&rsquo;d&uuml;r.<br />
-Kıbrıs Barış Harekatı esnasında u&ccedil;aklarımızın yanlışlıkla vurduğu gemimiz
Kocatepe&rsquo;dir.<br />
-T&uuml;rkiye&rsquo;nin ilk kadın bakanı T&uuml;rkan Akyol&rsquo;dur.<br />
-İlk şah tuğrası Yavuz Sultan Selim&rsquo;in tuğrasında g&ouml;r&uuml;lmeye başlanmıştır.<br />
-İlk T&uuml;rk&ccedil;e ezan İstanbul Fatih Camii&rsquo;nde okundu.<br />
-T&uuml;rkiye&rsquo;nin ilk televizyon yayını İstanbul&rsquo;dan yapıldı.<br />
-Cumhuriyet d&ouml;neminde kurulan ilk muhalefet partisi Terakkiperver Cumhuriyet
Fırka&rsquo;sır.<br />
-T&uuml;rkiye&rsquo;de ilk politika okulu Nazif &Uuml;lken tarafından kurulmuştur.<br />
-T&uuml;rkiye&rsquo;de en fazla milletvekili se&ccedil;ilen İsmet İn&ouml;n&uuml;&rsquo;d&uuml;r.(14 defa)<br />
-Ramazan &ccedil;adırı ilk kez 1995 yılında &Uuml;sk&uuml;dar Belediyesi tarafından kuruldu.<br />
-Cumhuriyet tarihinin en uzun s&uuml;reli azınlık h&uuml;k&uuml;meti Anasol-D h&uuml;k&uuml;metidir.<br />
-T&uuml;rkiye&rsquo;deki ilk mali kurum Emniyet Sandığı&rsquo;dır.<br />
-T&uuml;rkiye&rsquo;nin bilinen ilk erkek hemşiresi Murat Bektaş&rsquo;tır.<br />
-T&uuml;rkiye&rsquo;nin ilk haber ajansı Anadolu Ajansı&rsquo;dır.(1920)<br />
-T&uuml;rkiye&rsquo;nin ilk sınır &ouml;tesi harek&acirc;tı Kıbrıs &ccedil;ıkarmasıdır.<br />
-T&uuml;rkiye&rsquo;de kurulan ilk parti C.H.P&rsquo;dir.<br />
-Latin alfabesine resmi olarak ilk ge&ccedil;en T&uuml;rk devleti Azerbaycan&rsquo;dır.<br />
-T&uuml;rkiye&rsquo;nin en d&uuml;ş&uuml;k gelir elde edilen ili Muş&rsquo;tur.<br />
-Y&uuml;z&ouml;l&ccedil;&uuml;m&uuml; itibariyle en k&uuml;&ccedil;&uuml;k komşumuz Ermenistan&rsquo;dır.<br />
-T&uuml;rkiye B&uuml;y&uuml;k Millet Meclisi&rsquo;nin ilk başkanı M.Kemal&rsquo;dir.<br />
-T&uuml;rkiye&rsquo;de baskı tekniğini ilk kez İbrahim M&uuml;teferrika kurmuştur.<br />
-İlk TSE belgesi Yıldırım Bayezid devrinde &ccedil;ıkarılmıştır.<br />
-T&uuml;rkiye&rsquo;nin en y&uuml;ksek minaresi Selimiye Camisinde bulunur.<br />
-T&uuml;rkiye Cumhuriyeti devletini ilk kabul eden devlet Ermenistan&rsquo;dır.<br />
-Osmanlı Devleti&rsquo;nin ilk bankası Banka-i Der Saadet&rsquo;tir.(İstanbul Bankası)<br />
-T&uuml;rkiye&rsquo;de ilk u&ccedil;ak fabrikası Kayseri&rsquo;de a&ccedil;ıldı.<br />
-Kelaynak kuşları &uuml;lkemizde sadece Urfa&rsquo;nın Birecik il&ccedil;esinde bulunur.<br />
-En işlek kara sınırımız Yunanistan sınırıdır.<br />
-T&uuml;rkiye&rsquo;de &ouml;ld&uuml;r&uuml;len ilk başbakan Nihat Erim&rsquo;dir.<br />
-T&uuml;rkiye&rsquo;de ilk İngilizce gazete İlknur &Ccedil;evik tarafından &ccedil;ıkarılmıştır.<br />
-T&uuml;rkiye&rsquo;nin ilk haber spikeri Zafer Cilasun&rsquo;dur.<br />
-Mallarda kalite arayan ilk millet T&uuml;rkler&rsquo;dir.<br />
-T&uuml;rkiye dışarıya ilk olarak G.Kore&rsquo;ye asker g&ouml;ndermiştir.<br />
-T&uuml;rkiye&rsquo;nin en eski şehri Hakkari&rsquo;dir.<br />
-T&uuml;rkiye&rsquo;de taşk&ouml;m&uuml;r&uuml;n&uuml; ilk defa Uzun Mehmet bulmuştur.<br />
-Konya T&uuml;rkiye&rsquo;nin en uzun karayolu ağına sahiptir.<br />
-T&uuml;rkiye&rsquo;nin en kalabalık mezarlığı İstanbul Karacaahmet Mezarlığı&rsquo;dır.<br />
-D&uuml;nyada en fazla konuşulan diller sırasıyla ş&ouml;yledir: &Ccedil;ince, Hint&ccedil;e,
İngilizce, İspanyolca ve T&uuml;rk&ccedil;e&rsquo;dir.<br />
-T&uuml;rkiye&rsquo;de ilk milletvekili se&ccedil;imleri I.Meşrutiyet&rsquo;de yapıldı.<br />
-Ege B&ouml;lgesi&rsquo;nde en uzun kıyılara sahip ilimiz Muğla&rsquo;dır.<br />
-Karadeniz&rsquo;in en y&uuml;ksek dağı Ka&ccedil;kar Dağı&rsquo;dır.<br />
-Taşk&ouml;m&uuml;r&uuml; ilk defa Zonguldak&rsquo;ta &ccedil;ıkarılmıştır.<br />
-T&uuml;rkiye&rsquo;de petrol arama &ccedil;alışmaları ilk defa İskenderun&rsquo;da yapılmıştır.<br />
-T&uuml;rkiye&rsquo;nin en zengin boksit yatakları Seydişehir&rsquo;de bulunur.<br />
-T&uuml;rkiye&rsquo;de heyelan en &ccedil;ok kış mevsiminde g&ouml;r&uuml;l&uuml;r.<br />
-T&uuml;rkiye&rsquo;nin doğusu ile batısı arasında 76 dakikalık zaman farkı vardır.<br />
-T&uuml;rkiye&rsquo;nin ilk turistik yerleşim yeri &Ccedil;eşme&rsquo;dir.<br />
-K&uuml;mes hayvancılığı en &ccedil;ok Marmara B&ouml;lgesi&rsquo;de farklıdır.<br />
-T&uuml;rkiye&rsquo;nin en doğu ucunda Iğdır ili bulunur.<br />
-T&uuml;rkiye&rsquo;nin &ccedil;ay yetiştirilen tek y&ouml;resi D.Karadeniz&rsquo;dir.<br />
-T&uuml;rkiye&rsquo;de r&uuml;zgarın en etkili olduğu yer İ&ccedil; Anadolu&rsquo;dur.<br />
-T&uuml;rkiye&rsquo;nin en az g&ouml;&ccedil; veren b&ouml;lgesi Marmara B&ouml;lgesidir.<br />
-T&uuml;rkiye&rsquo;nin en az ormana sahip b&ouml;lgesi G.Anadolu B&ouml;lgesi&rsquo;dir.<br />
-İ&ccedil; Anadolu B&ouml;lgesi&rsquo;nin en y&uuml;ksek yeri Erciyes Dağı&rsquo;dır.<br />
-Ulaşım yapılabilinen tek akarsuyumuz Bartın &Ccedil;ayı&rsquo;dır.<br />
-&Uuml;lkemizde ilk dokuma fabrikası Nazilli&rsquo;de a&ccedil;ılmıştır.<br />
-&Uuml;lkemizde ilk şeker fabrikası Uşak&rsquo;ta a&ccedil;ılmıştır.<br />
-&Uuml;lkemizde ilk demir-&ccedil;elik fabrikası Karab&uuml;k&rsquo;te a&ccedil;ılmıştır.<br />
-Kayısı,fındık,&ccedil;ay &uuml;retiminde &uuml;lkemiz ilk sırada yer alır.<br />
-D&uuml;nya bor rezervlerin %70&prime;i &uuml;lkemizde yer alır.<br />
-&Uuml;lkemizde ipek b&ouml;cek&ccedil;iliği en fazla Marmara B&ouml;lgesi&rsquo;nde yapılır.<br />
-T&uuml;rkiye&rsquo;nin en fazla kara sınırı Suriye ile(877),en az kara sınırı ise
Nah&ccedil;ıvan iledir(10)<br />
-Ege kıyıları en uzun kıyımızdır.<br />
-&Uuml;lkemizin en b&uuml;y&uuml;k g&ouml;l&uuml; Van G&ouml;l&uuml;&rsquo;d&uuml;r.<br />
-T&uuml;rkiye&rsquo;nin en uzun akarsuyu,Kızılırmak&rsquo;tır.<br />
-Zonguldak k&ouml;m&uuml;r yatakları birinci zamanda oluşmuştur.<br />
-&Ccedil;anakkale ve İstanbul boğazları d&ouml;rd&uuml;nc&uuml; zamanda oluşmuştur.<br />
-Kıyılarımıza en yakın ada Midilli Adası&rsquo;dır.<br />
-T&uuml;rkiye dışında T&uuml;rk bayrağının dalgalandığı tek kale Caber Kalesi&rsquo;dir</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal"><strong><span style="text-decoration: underline;">D&Uuml;NYA&rsquo;NIN EN&rsquo;LERİ:</span></strong><br />
D&uuml;nyanın en y&uuml;ksek şelalesi: Angel-Venezuela&ndash;1.000 m.<br />
D&uuml;nyanın en b&uuml;y&uuml;k nehri: Nil-Afrika<br />
D&uuml;nyanın en y&uuml;ksek dağı: Everest-Asya&ndash;8.848 m.<br />
D&uuml;nyanın en b&uuml;y&uuml;k &ccedil;&ouml;l&uuml;: B&uuml;y&uuml;k Sahra &Ccedil;&ouml;l&uuml;-Orta/Kuzey Afrika<br />
D&uuml;nyanın en b&uuml;y&uuml;k yanardağı: Tambora-Endonezya<br />
D&uuml;nyanın en b&uuml;y&uuml;k mağarası: Carlsbad Mağarası-New Mexico, ABD<br />
D&uuml;nyanın en b&uuml;y&uuml;k g&ouml;l&uuml;: Hazar Denizi-Orta Asya&ndash;394.299 km&sup2;<br />
D&uuml;nyanın en b&uuml;y&uuml;k adası: Gr&ouml;nland-Kuzey Atlantik&ndash;2.175.597 km&sup2;<br />
D&uuml;nyanın en sıcak yeri: Al&rsquo;Aziziyah-Libya&ndash;57,7 C<br />
D&uuml;nyanın en soğuk yeri: Vostock II- -89,2 C<br />
D&uuml;nyanın en kalabalık &uuml;lkesi: &Ccedil;in&ndash;1.237.000.000 kişi<br />
D&uuml;nyanın en geniş &uuml;lkesi: Rusya&ndash;10.610.083 km&sup2;<br />
D&uuml;nyanın en k&uuml;&ccedil;&uuml;k &uuml;lkesi: Vatikan&ndash;0.272 km&sup2;.<br />
D&uuml;nyanın en kalabalık şehri: Tokyo-Japonya&ndash;26.500.000 kişi<br />
D&uuml;nyanın en uzun binası: Suyong Bay Tower-Pusan(G&uuml;ney Kore): 88 kat 462 m.<br />
D&uuml;nyanın en uzun demiryolu t&uuml;neli: Seikan-Japonya&ndash;53,9 km.<br />
D&uuml;nyanın en uzun karayolu t&uuml;neli: St.Gotthard-İsvi&ccedil;re-16.4 km.<br />
D&uuml;nyanın en uzun kanalı: Panama kanalı-Panama&ndash;81,5 km.<br />
D&uuml;nyanın en uzun k&ouml;pr&uuml;s&uuml;: Akashi-Japonya&ndash;1.990 m.<br />
D&uuml;nyada en &ccedil;ok konuşulan dil: &Ccedil;ince (mandarin)-885.000.000 kişi<br />
D&uuml;nyanın en &ccedil;ok &uuml;lke ile sınırı olan &uuml;lke: &Ccedil;in (15 &uuml;lke ile sınırı var)<br />
D&uuml;nyanın en y&uuml;ksek yerleşim yeri: Webzhuan, &Ccedil;in-Deniz seviyesinden 5.090 m. Yukarıda<br />
D&uuml;nyanın en al&ccedil;ak yerleşim yeri: Calipatria, Kaliforniya, ABD &ndash; deniz
seviyesinin 54 mt. Altında<br />
D&uuml;nyanın en uzun kesintisiz sınırı: ABD-Kanada sınırı.</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">&nbsp;</p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfaz Koruma Memuru (Gardiyan) Nedir ?</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Cezaevi ve ıslah evlerinde barındırılan su&ccedil;luların ihtiya&ccedil;larını
karşılayan ve bunların ıslahını sağlayarak topluma yeniden kazandırılmasına
yardım eden meslek elemanıdır. Eski adıyla gardiyan yeni adıyla infaz koruma
memurudur.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfaz Koruma Memurunun G&ouml;revleri Nelerdir?</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Cezaevine giren tutuklu ve h&uuml;k&uuml;ml&uuml;lerin &uuml;zerini arar ve
taşıdıkları kıymetli eşyayı emniyet altında bulundurur.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Cezaevinde bulunan tutuklu ve h&uuml;k&uuml;ml&uuml;ler hakkında bir takım
kayıtları tutar.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Tutuklu ve h&uuml;k&uuml;ml&uuml;leri koğuşlarına g&ouml;t&uuml;rerek koğuş kapılarını
kilitler.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Koğuşları belirli periyotlarla kontrol eder, &ccedil;alışan tutuklulara
nezaret eder.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Kapı, pencere ve bah&ccedil;e kapılarının iyi bir şekilde kapatılıp
kapatılmadığını ve ka&ccedil;ma girişimiyle ilgili herhangi bir &ccedil;alışma olup
olmadığını muayene ve tespit eder.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Tutuklu ve h&uuml;k&uuml;ml&uuml;leri yemek, banyo ihtiya&ccedil;larını , revire
&ccedil;ıkarma, g&ouml;r&uuml;şlere g&ouml;t&uuml;r&uuml;l&uuml;p getirme, mahkemeye hazırlama, tıraş, kantin
ihtiya&ccedil;larının temini, y&ouml;neticilerle g&ouml;r&uuml;şt&uuml;r&uuml;lmesi işlemini yapar.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">G&uuml;nde en az 3 defa h&uuml;k&uuml;ml&uuml;lerin ve tutukluların sayımını yapar.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Cezaevlerinde &ccedil;ıkabilecek olaylara anında m&uuml;dahale ederek olayın
b&uuml;y&uuml;mesini engeller ve s&uuml;kunetin devamını sağlar.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Cezaevinde kısmi ve genel aramaları yaparak bulundurulması ve
girmesi yasak olan maddelerin girişine engel olur.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Ağır ceza merkezi olmayan (kaza ceza evi) yerlerde katip, idari
memurunun bulunmadığı ceza evlerinde sevk ve idareden b&uuml;t&uuml;n olarak sorumludur.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Cezaevinin temizliğinden sorumludur.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: red;">Cezaevi M&uuml;d&uuml;r&uuml;n&uuml;n G&ouml;revleri Nelerdir?</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">a) Kurum personeli &uuml;zerinde mevzuatın &ouml;ng&ouml;rd&uuml;ğ&uuml; şekilde g&ouml;zetim
ve denetim hakkını kullanmak,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">b) Kurum personeline verilen yazılı veya s&ouml;zl&uuml; emirlerin yerine
getirilip getirilmediğini izlemek ve denetlemek,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">c) Mevzuat ve yetkili mercilerce verilen emirler &ccedil;er&ccedil;evesinde
kurumun genel idare ve işyurduna ait hesap işlerinin y&uuml;r&uuml;t&uuml;lmesini ve
denetimini yapmak,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">d) H&uuml;k&uuml;ml&uuml;lerin iyileştirilmesi, bilgilerinin artırılması,
at&ouml;lye &ccedil;alışmaları, kişisel uğraşlarının d&uuml;zenlenmesi ve geliştirilmesinin
sağlanması bakımından mevzuat h&uuml;k&uuml;mlerini uygulamak ve sağlık durumlarıyla
yakından ilgilenmek,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">e) Kamu kurum ve kuruluşları ile bakanlıklar tarafından
istenilen istatistiki bilgi ve belgelerin hazırlanmasını sağlamak ve Cumhuriyet
başsavcılığına sunmak,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">f) Haftada en az bir defa olmak &uuml;zere g&uuml;nd&uuml;zleri, on beş g&uuml;nde
en az bir defa olmak &uuml;zere de geceleri kurumun b&uuml;t&uuml;n faaliyetlerini tetkik
ederek, işlerin mevzuat ve emirler &ccedil;er&ccedil;evesinde y&uuml;r&uuml;y&uuml;p y&uuml;r&uuml;mediğini denetlemek
ve aldığı sonu&ccedil;ları ve g&ouml;rd&uuml;ğ&uuml; eksiklikleri denetleme defterine kaydetmek ve
takip etmek,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">g) Kurum hizmetleriyle ilgili genel ihtiya&ccedil;ları, &ouml;ncelikleri,
bir sonraki yılda yapılacak işleri belirlemek ve bu konularla ilgili tahmini
gider verilerini hazırlayarak Bakanlığa sunmak,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">h) Asayiş, g&uuml;venlik, sağlık ve benzeri konularda ortaya &ccedil;ıkan
sorunlarla ilgili gecikmeksizin &ouml;nlem almak, &ouml;nlemlerin yetersiz kalması
halinde, durumu derhal Cumhuriyet başsavcılığı aracılığıyla Bakanlığa
bildirmek,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">ı) Mevzuatla verilen diğer g&ouml;revleri yapmak.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">a) Kurum personeli &uuml;zerinde mevzuatın &ouml;ng&ouml;rd&uuml;ğ&uuml; şekilde g&ouml;zetim
ve denetim hakkını kullanmak,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">b) Kurum personeline verilen yazılı veya s&ouml;zl&uuml; emirlerin yerine
getirilip getirilmediğini izlemek ve denetlemek,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">c) Mevzuat ve yetkili mercilerce verilen emirler &ccedil;er&ccedil;evesinde
kurumun genel idare ve işyurduna ait hesap işlerinin y&uuml;r&uuml;t&uuml;lmesini ve
denetimini yapmak,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">d) H&uuml;k&uuml;ml&uuml;lerin iyileştirilmesi, bilgilerinin artırılması,
at&ouml;lye &ccedil;alışmaları, kişisel uğraşlarının d&uuml;zenlenmesi ve geliştirilmesinin
sağlanması bakımından mevzuat h&uuml;k&uuml;mlerini uygulamak ve sağlık durumlarıyla
yakından ilgilenmek,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">e) Kamu kurum ve kuruluşları ile bakanlıklar tarafından
istenilen istatistiki bilgi ve belgelerin hazırlanmasını sağlamak ve Cumhuriyet
başsavcılığına sunmak,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">f) Haftada en az bir defa olmak &uuml;zere g&uuml;nd&uuml;zleri, on beş g&uuml;nde
en az bir defa olmak &uuml;zere de geceleri kurumun b&uuml;t&uuml;n faaliyetlerini tetkik
ederek, işlerin mevzuat ve emirler &ccedil;er&ccedil;evesinde y&uuml;r&uuml;y&uuml;p y&uuml;r&uuml;mediğini denetlemek
ve aldığı sonu&ccedil;ları ve g&ouml;rd&uuml;ğ&uuml; eksiklikleri denetleme defterine kaydetmek ve
takip etmek,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">g) Kurum hizmetleriyle ilgili genel ihtiya&ccedil;ları, &ouml;ncelikleri,
bir sonraki yılda yapılacak işleri belirlemek ve bu konularla ilgili tahmini
gider verilerini hazırlayarak Bakanlığa sunmak,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">h) Asayiş, g&uuml;venlik, sağlık ve benzeri konularda ortaya &ccedil;ıkan
sorunlarla ilgili gecikmeksizin &ouml;nlem almak, &ouml;nlemlerin yetersiz kalması
halinde, durumu derhal Cumhuriyet başsavcılığı aracılığıyla Bakanlığa
bildirmek,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">ı) Mevzuatla verilen diğer g&ouml;revleri yapmak.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfaz Koruma Memurları &Ccedil;alışma Ortamı Ve
Koşulları Nasıldır?&nbsp;</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfaz Koruma Memurları genelde kapalı, a&ccedil;ık ve yarı a&ccedil;ık ceza
evlerinde, bunlara bağlı at&ouml;lye ve a&ccedil;ık alanlarda &ccedil;alışırlar,Teknolojik gelişme
bu mesleğin icrasını kolaylaştırmaktadır (kapalı devre TV sistemi gibi).
Gardiyanlar; cezaevi &uuml;st y&ouml;neticileriyle, tutuklularla ve h&uuml;k&uuml;ml&uuml;lerle, halktan
kişilerle, meslektaşlarıyla, savcılarla, hakimlerle, avukatlarla, askerlerle,
iletişim i&ccedil;indedir.H&uuml;k&uuml;ml&uuml; ve tutuklular tarafından tehditler alabilir, fiili
saldırıya uğrayabilirler. G&ouml;rev bitiminde bir takım sorunlarla da
karşılaşabilir. İsyanlarda rehin olma, yaralanma vb. olayları da olabilir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfaz Koruma Memurları Hizmet İ&ccedil;i Eğitim
S&uuml;reci:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfaz koruma memurluğu mesleğine &nbsp;yeni başlayan meslek
elemanının h&uuml;k&uuml;ml&uuml; ve tutuklularla olan ilişkilerinin daha sağlıklı olabilmesi
i&ccedil;in hizmet-i&ccedil;i eğitim uygulanır,Bu eğitimde; cezaevi y&ouml;netimiyle ilgili daha
fazla bilgi almaları sağlanır, h&uuml;k&uuml;ml&uuml; ve tutuklularla daha sağlıklı,diyalog
kurmaları i&ccedil;in T&uuml;rk&ccedil;e&rsquo;yi daha iyi kullanma yetenekleri geliştirilir. Cezaevi
mevzuatı, h&uuml;k&uuml;ml&uuml; ve tutukluları ilgilendiren kanunlar hakkında bilgi
verilir,Bu mesleğe girenlere zinde kalmaları i&ccedil;in yakın d&ouml;v&uuml;şme kuralları
&ouml;ğretilir. Cezaevine girmesi yasaklanan maddelerin tanıtılması i&ccedil;in dersler
verilir. (Esrar, morfin, kokain, eroin ve uyuşturucu haplar.) Meslek i&ccedil;in
&ouml;nemli olan dersler; Psikoloji, T&uuml;rk&ccedil;e, İnfaz Hukuku, Cezaevi İdaresi, Genel
Hukuk, Kriminoloji, Narkotik, Davranış Bilimleri, Ceza Mahkemeleri ,İlk Yardım
ve Sağlık, Beden Eğitimi vb. dersler.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfaz Koruma Memurluğu Meslekte İlerleme:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Adalet Bakanlığına bağlı cezaevlerine İnfaz ve Koruma Memuru
olarak giren devlet memuru g&ouml;rev i&ccedil;erisinde g&ouml;sterdiği başarı durumuna g&ouml;re
yapılan sınavla İnfaz ve Koruma Baş Memurluğuna (baş gardiyan) y&uuml;kselme
imkanına sahiptir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Y&uuml;ksek okul mezunu olan İnfaz ve Koruma Memurları Adalet
Bakanlığı&rsquo;nın a&ccedil;tığı sınavlarda idare memurluğu sınavını kazanabilirlerse
cezaevi 2. M&uuml;d&uuml;r ve 1. M&uuml;d&uuml;r kademelerine kadar y&uuml;kselebilirler.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfaz Koruma Memuru''nun Kullandığı Ara&ccedil;-Gere&ccedil;
ve Donanımlar:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Bilgisayar,Hijyen Seti,Duyarlı Kapı,Kartuş ve Toner,El
Dedekt&ouml;r&uuml;,Kırtasiye Malzemeleri,El Feneri,Temizlik
Seti,Eldiven,Kaset,Faks,CD/DVD,Fotokopi Makinası,İlk Yardım
Seti,Jop,Kalkan,Kamera sistemleri,Kapalı devre anons sistemi,Kask,Kaşe-m&uuml;h&uuml;r,Kayıt
cihazları,Kelep&ccedil;e,Koruma Elbisesi,Manyetik Kapı,Matbu defterler,Matbu
formlar,Matbu tutanaklar,Monit&ouml;rler,Parmak İzi Tarayıcısı (El
Biyometrisi),Retina Tarayıcısı (G&ouml;z
Biyometrisi),Tarayıcı,Telefon,Telsiz,Tepeg&ouml;z,Tv-Radyo yayın sistemi,&Uuml;niforma,X-Ray
cihazı,Yangın S&ouml;nd&uuml;rme Seti,Yazıcı</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfaz Koruma Memuru İ&ccedil;in Gerekli Olan Bilgi Ve
Beceriler:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Ara&ccedil; gere&ccedil; ve ekipman bilgisi,Bilgisayar bilgisi,&Ccedil;evre d&uuml;zenleme
bilgisi,Daktilo/ klavye kullanma bilgisi,Dinleme yeteneği,Ekip i&ccedil;inde &ccedil;alışma
yeteneği,G&ouml;zlem yeteneği,Hijyen bilgisi,İkna yeteneği,İletişim Yeteneği,İlk
yardım bilgisi,İnsan psikolojisi bilgisi,İş yeri &ccedil;alışma prosed&uuml;rleri
bilgisi,İş&ccedil;i sağlığı ve iş g&uuml;venliği &ouml;nlemleri bilgisi,Karar verme
yeteneği,Kayıt tutma yeteneği,Liderlik yeteneği,Malzeme bilgisi,Mesleğe ilişkin
yasal d&uuml;zenlemeler bilgisi,Mesleki teknolojik gelişmelere ilişkin bilgi,Mesleki
terim bilgisi,Organizasyon yeteneği,&Ouml;ğrenme yeteneği,&Ouml;ğretme yeteneği,Problem
&ccedil;&ouml;zme yeteneği,Protokol bilgisi,Yakın D&ouml;v&uuml;ş ve Savunma Bilgisi,Yazışma
Kuralları Bilgisi</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">T&Uuml;RK İNFAZ TEŞKİLATI:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Kesinleşen mahkumiyet kararları, ilgili mahkemece Cumhuriyet
başsavcılığına g&ouml;nderilir. Buna g&ouml;re cezanın infazı, Cumhuriyet savcısı
tarafından izlenir ve denetlenir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">T&uuml;rk İnfaz teşkilatı, Ceza ve Tevkifevleri Genel M&uuml;d&uuml;rl&uuml;ğ&uuml;
b&uuml;nyesinde merkez ve taşra teşkil&acirc;tı olarak &ouml;rg&uuml;tlenmiştir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Merkez Teşkil&acirc;tı; Bakanlık, Genel M&uuml;d&uuml;rl&uuml;k ve alt birimlerinden
oluşmaktadır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Taşra Teşkil&acirc;tı; Cumhuriyet başsavcılıkları, personel eğitim
merkezleri, ceza infaz kurumları ve tutukevleri ile denetimli serbestlik ve
yardım merkezlerinden oluşmaktadır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">1-Cumhuriyet Başsavcılıkları:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;Ceza
ve G&uuml;venlik Tedbirlerinin İnfazı Hakkındaki Kanununun 5.maddesine g&ouml;re mahkeme,
kesinleşen ve yerine getirilmesini onayladığı cezaya &nbsp;ilişkin h&uuml;km&uuml; Cumhuriyet
Başsavcılığına g&ouml;nderir. Bu h&uuml;kme g&ouml;re cezanın infazı Cumhuriyet savcısı
tarafından izlenir ve denetlenir. Mahkemelerce verilen ve kesinleşen cezalar
Cumhuriyet başsavcılıklarınca infaz olunur. Ayrıca, CMK&rsquo;nun 100&rsquo;&uuml;nc&uuml; maddesi
gereğince tutuklanmasına karar verilen kişiler, Cumhuriyet başsavcılıklarının
kuruma sevk emri olmadan ceza infaz kurumlarına kabul edilemezler. Bu durum
tahliye kararlarının yerine getirilmesinde de s&ouml;z konusudur.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Ayrıca Cumhuriyet başsavcıları, cezaevlerinde g&ouml;rev yapan bazı
merkez ve taşra personelinin hem sicil amiri hem de disiplin amiridir. Bunun
yanında adl&icirc; yargı adalet komisyonlarında &uuml;ye olarak g&ouml;rev yapmakta ve taşra
personeli olan infaz personelinin atama, g&ouml;revde y&uuml;kselme, g&ouml;revden
uzaklaştırılma, disiplin işlemleri, yargı &ccedil;evresi i&ccedil;indeki nakilleri ve ge&ccedil;ici
g&ouml;revlendirilmeleri gibi &ouml;zl&uuml;k işlemlerine bakmaktadır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Bu g&ouml;revlerine il&acirc;veten ceza infaz kurumlarının diğer
kuruluşlarla ilişkilerinde temsil yetkisi Cumhuriyet başsavcılıklarındadır.
Ceza infaz kurumlarının yazışmaları Cumhuriyet başsavcılıkları aracılığıyla
yapılmaktadır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Bu itibarla, Cumhuriyet savcıları yargısal g&ouml;revleri ayrık olmak
&uuml;zere infaz hizmetlerine ilişkin g&ouml;revleri bakımından Genel M&uuml;d&uuml;rl&uuml;ğ&uuml;n taşra
teşkil&acirc;tını oluşturmaktadır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">2- Personel Eğitim Merkezleri:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;Ceza
infaz sisteminin taşra teşkil&acirc;tını oluşturan diğer bir birimdir. &Uuml;lkemizde ceza
infaz kurumları ve tutukevleri personeli ge&ccedil;mişte yeterli g&ouml;r&uuml;lmeyen bir hizmet
&ouml;ncesi ve hizmet i&ccedil;i eğitim ile eğitilmekte iken 29.7.2002 tarihinde kabul edilen
4769 sayılı Ceza İnfaz Kurumları ve Tutukevleri Personel Eğitim Merkezleri
Kanunu ile ceza infaz kurumları personelinin T&uuml;rkiye&rsquo;nin beş b&ouml;lgesinde
kurulacak olan eğitim merkezlerinde eğitimi &ouml;ng&ouml;r&uuml;lm&uuml;şt&uuml;r.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Bu kurumlarda ceza infaz kurumlarında ve tutukevlerinde g&ouml;rev
yapacak olan personelden idare memurluğu &ouml;ğrencileri ile infaz ve koruma
memurluğu &ouml;ğrencilerinin hizmet &ouml;ncesi eğitimi ile bu kurumlarda g&ouml;rev yapan
personelin aday memurluk, hizmet i&ccedil;i ve g&ouml;revde y&uuml;kselme eğitimleri
yapılacaktır. Bu kurumlardan Ankara, İstanbul ve Erzurum Eğitim Merkezleri
hizmete girmiş durumda olup, diğer ikisinin kuruluş &ccedil;alışmaları devam
etmektedir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Bu merkezlerde h&acirc;kim veya savcı sınıfından olan bir m&uuml;d&uuml;r ve bir
m&uuml;d&uuml;r yardımcısı ile yeteri kadar idar&icirc; personel ile &ouml;ğretim g&ouml;revlisi
bulunmaktadır. Kanun gereğince s&ouml;z konusu personel eğitim merkezleri Ceza ve
Tevkifevleri Genel M&uuml;d&uuml;rl&uuml;ğ&uuml;ne bağlıdır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">3- Ceza İnfaz Kurumları:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;Mahkemelerce
usul&uuml;ne uygun olarak yargılanan ve herhangi bir h&uuml;rriyeti bağlayıcı cezaya
mahk&ucirc;m edilen kişilerin barındırıldıkları ve eğitilerek yeniden topluma
kazandırıldıkları kurumlardır. Bu kurumlarda hizmetler kurum i&ccedil;inde &ouml;rg&uuml;tlenmiş
bulunan &ccedil;eşitli kurullar, heyetler, komisyonlar ve servisler tarafından yerine
getirilir. Bunlar, İdare Kurulu, Disiplin Kurulu, Yayın Se&ccedil;ici Kurul, Mektup
Okuma Komisyonu, İhale Komisyonu, Muayene Kabul Heyetidir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Personel Rejimi ve Eğitimi:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Ceza ve infaz kurumlarında g&ouml;rev yapan idar&icirc; personel, fak&uuml;lte
ve y&uuml;ksekokul mezunu olup, Başbakanlık tarafından yapılan Devlet Memurluğu
Sınavı ile mesleğe alınırlar. Personel genellikle psikolog, sosyolog, sosyal
&ccedil;alışmacı, &ouml;ğretmen, iktisad&icirc; ve idar&icirc; bilimler ile hukuk fak&uuml;ltesi mezunları
arasından se&ccedil;ilirler. Uygulamada &ccedil;ok &ccedil;eşitli meslekten gelen m&uuml;d&uuml;rler
bulunmaktadır. M&uuml;d&uuml;rler dışardan atanmayıp idare memuru olarak kurum i&ccedil;erisinde
yetiştirilirler.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfaz ve koruma personeli yukarıda bahsi ge&ccedil;en sınavı kazananlar
arasından mahall&icirc; komisyonlarca atanırlar. En az lise mezunu olma şartı
bulunup, y&uuml;ksekokul mezunları tercih edilir. Personelin eğitimi hizmet &ouml;ncesi,
hizmet i&ccedil;i ve g&ouml;revde y&uuml;kselme kursları ile sağlanır. Kurslarda genel hukuk,
ceza hukuku, infaz hukuku, y&ouml;netim hukuku, uluslararası cezaevi standartları,
sosyal ilişkiler, sosyal hizmetler, psikoloji, kriminoloji, beden eğitimi ve
insan hakları gibi dersler okutulur. Ayrıca ilgili konularda seminer ve
konferanslar verilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Kurum personeline g&ouml;revi i&ccedil;erisinde her an başvurabileceği bir
de el kitap&ccedil;ığı verilir. Bu kitap&ccedil;ıkta personelin g&ouml;rev, yetki ve
sorumlulukları a&ccedil;ıklanır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Kadın ve &ccedil;ocuk cezaevinde &ccedil;alışan personele bu konuda &ouml;zel
eğitim verilmelidir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Cezaevlerinin G&uuml;venliği:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Kapalı ceza ve infaz kurumları ile tutukevlerinde i&ccedil; g&uuml;venlik
Adalet Bakanlığına bağlı infaz ve koruma personeli tarafından yerine getirilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Bu kurumlarda dış g&uuml;venlik ise İ&ccedil;işleri Bakanlığına bağlı
Jandarma Teşkil&acirc;tı tarafından sağlanır. Tutuklu ve h&uuml;k&uuml;ml&uuml;lerin her t&uuml;rl&uuml; nakil
ve sevk işlemleri ile isyan ve firar olaylarına m&uuml;dahale bu birim tarafından
yerine getirilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">A&ccedil;ık cezaevleri ile &ccedil;ocuk ıslahevlerinde i&ccedil; ve dış g&uuml;venlik
sadece infaz ve koruma personeli tarafından sağlanır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Cezaevlerinin Denetimi</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Ceza ve infaz kurumları Adalet Bakanlığına bağlı olan ve
h&acirc;kimlik ve savcılık mesleğinden gelen m&uuml;fettişler ile Genel M&uuml;d&uuml;rl&uuml;ğe bağlı
kontrol&ouml;rler tarafından her yıl denetlenir (Kontrol&ouml;rler h&acirc;kim ve savcılar ile
adl&icirc; işlemleri denetleyemezler).</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Diğer yandan cezaevleri d&uuml;zenli aralıklarla ve her iki ayda bir
defadan az olmamak &uuml;zere sivil toplum &uuml;yelerinden oluşan izleme kurulları
tarafından denetlenir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Aynı zamanda, her ağır ceza merkezi ile asliye ceza mahkemesi
bulunan il&ccedil;elerde tutuklu ve h&uuml;k&uuml;ml&uuml;lerin cezaevi idaresi ve infaz rejimi
hakkındaki şik&acirc;yetleri ile disiplin cezalarını inceleyen infaz h&acirc;kimlikleri
bulunmaktadır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&Ouml;te yandan, ceza ve infaz kurumları TBMM İnsan Hakları İnceleme
Komisyonu, Başbakanlık İnsan Hakları Başkanlığı, Adalet Bakanlığı, İnsan
Haklarından Sorumlu Devlet Bakanlığı, Ceza ve Tevkifevleri Genel M&uuml;d&uuml;rl&uuml;ğ&uuml;,
Avrupa İşkenceyi &Ouml;nleme Komitesi ile Birleşmiş Milletler İşkenceye Karşı Komite
tarafından denetlenebilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Ayrıca Cumhuriyet başsavcıları da kurumları sık sık denetlemek
zorundadırlar.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">4- Denetimli serbestlik ve yardım merkezleri:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;Adl&icirc;
kontrol altında tutulmasına karar verilen, &nbsp;şartla tahliyesine karar
verilen, cezası tecil edilen ya da hapis dışı bir ceza veya tedbire (kamu
hizmetlerinde &ccedil;alışma, zorunlu eğitim alma, zorunlu tedaviye t&acirc;bi tutulma,
belirli meslek ve sanattan men edilme, ehliyet ve ruhsatın geri alınması,
belirli yerlere gidememe vb. gibi) &nbsp;mahk&ucirc;m &nbsp;edilen kişilerin
cezalarının infaz edildiği ve bu h&uuml;k&uuml;ml&uuml;lere psiko-sosyal hizmet ile olabilecek
diğer desteğin sağlandığı, yargılanan kişiler hakkında sosyal araştırma
raporlarının yazıldığı, tahliye sonrasında mahk&ucirc;mlara iş ve kredi sağlandığı,
ayrıca su&ccedil; mağduruna yardım yapıldığı Cumhuriyet Başsavcılıklarına bağlı
kurumlardır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfazda temel ilke</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(1) Eşitlik: Ceza ve g&uuml;venlik tedbirlerinin infazına ilişkin
kurallar h&uuml;k&uuml;ml&uuml;lerin ırk, dil, din, mezhep, milliyet, renk, cinsiyet, doğum,
felsef&icirc; inan&ccedil;, mill&icirc; veya sosyal k&ouml;ken ve siyas&icirc; veya diğer fikir yahut
d&uuml;ş&uuml;nceleri ile ekonomik g&uuml;&ccedil;leri ve diğer toplumsal konumları y&ouml;n&uuml;nden ayırım
yapılmaksızın ve hi&ccedil;bir kimseye ayrıcalık tanınmaksızın uygulanır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(2) İnsan hak ve onuruna saygı: Ceza ve g&uuml;venlik tedbirlerinin
infazında zalimane, insanlık dışı, aşağılayıcı ve onur kırıcı davranışlarda
bulunulamaz.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; İnfazda temel
ama&ccedil;</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Ceza ve
g&uuml;venlik tedbirlerinin infazı ile ulaşılmak istenilen&nbsp;<strong>temel ama&ccedil;</strong>, &ouml;ncelikle
genel ve &ouml;zel &ouml;nlemeyi sağlamak, bu maksatla h&uuml;k&uuml;ml&uuml;n&uuml;n yeniden su&ccedil; işlemesini
engelleyici etkenleri g&uuml;&ccedil;lendirmek, toplumu su&ccedil;a karşı korumak; h&uuml;k&uuml;ml&uuml;n&uuml;n,
yeniden sosyalleşmesini teşvik etmek,&nbsp; &uuml;retken ve kanunlara, nizamlara ve
toplumsal kurallara saygılı, sorumluluk taşıyan bir yaşam bi&ccedil;imine uyumunu
kolaylaştırmaktır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; İnfazın koşulu
ve dayanağı</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfazın en
&ouml;nemli koşulu,&nbsp; mahkumiyet kararının kesinleşmesidir. Su&ccedil; işlendikten
sonra yapılan soruşturma ve kovuşturma neticesinde mahkemece verilen mahkumiyet
kararı, ya kanun yoluna başvurulmaksızın bu konuda yasada &ouml;n g&ouml;r&uuml;len s&uuml;renin
dolmasıyla kesinleşir. Ya da kanun yoluna başvurulması neticesi ilgili kararın
onanmasıyla kesinleşir. Mahk&ucirc;miyet h&uuml;k&uuml;mleri, bu şekilde &nbsp;kesinleşmedik&ccedil;e
infaz olunamaz.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Bu bilgilerden hareketle infazın dayanağı, kesinleşmiş bir
mahkumiyet kararı, diğer bir anlatımla mahkumiyet ilamıdır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">T&uuml;rk infaz teşkilatı<br />
Kesinleşen mahkumiyet kararları, ilgili mahkemece Cumhuriyet başsavcılığına
g&ouml;nderilir. Buna g&ouml;re cezanın infazı, Cumhuriyet savcısı tarafından izlenir ve
denetlenir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">T&uuml;rk İnfaz teşkilatı, Ceza ve Tevkifevleri Genel M&uuml;d&uuml;rl&uuml;ğ&uuml;
b&uuml;nyesinde merkez ve taşra teşkil&acirc;tı olarak &ouml;rg&uuml;tlenmiştir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Merkez Teşkil&acirc;tı;&nbsp;</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Bakanlık, Genel M&uuml;d&uuml;rl&uuml;k ve alt birimlerinden
oluşmaktadır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Taşra Teşkil&acirc;tı</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">; Cumhuriyet başsavcılıkları, personel eğitim merkezleri, ceza
infaz kurumları ve tutukevleri ile denetimli serbestlik ve yardım
merkezlerinden oluşmaktadır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İNFAZ HUKUKUNUN TEMEL KAVRAMLARI</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Su&ccedil;:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Su&ccedil;,</span></strong><span class="apple-converted-space"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></strong></span><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">hukuk
terminolojisine g&ouml;re<span class="apple-converted-space"><strong>&nbsp;</strong></span>kendisine
yaptırım olarak ceza konulmuş eylemdir. Başka bir tanıma g&ouml;re kanun ile korunan
kuralların bozulmasıdır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Su&ccedil;un d&ouml;rt genel unsuru bulunmaktadır:</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">1-Kanunilik unsuru: İşlenen fiilin kanundaki su&ccedil; tanımına uygun
olması, kanunun s&ouml;z konusu eylemi doğrudan su&ccedil; olarak tanımlamış olması
gerekir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">2-Maddi unsur: Bir fiil bulunmalıdır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">3-Hukuka aykırılık unsuru: Fiil hukuk kurallarına aykırı
olmalıdır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">4-Manevi Unsur: Fiil bilerek ve istenerek işlenmelidir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Su&ccedil;un maddi konusu; su&ccedil;tan etkilenen insan veya şeydir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Su&ccedil;un hukuki konusu ise bir ceza normu ile korunan diğer bir
anlatımla su&ccedil;la ihlal edilen hak ve menfaattir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
Ceza:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Hukuk terminolojisinde ceza; kanunlarla &ouml;ng&ouml;r&uuml;len, topluma ve
bireye belli &ouml;l&ccedil;&uuml;de zarar veren fiillerin karşılığı olarak su&ccedil; failine ızdırap
&ccedil;ektirmek amacıyla, bazı mahrumiyetlere tabi tutan, kazai bir kararla ve failin
kusurluluğu ile orantılı ve onun şahsına uygun olarak h&uuml;kmedilen korkutucu bir
yaptırım olarak tanımlanabilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">TCK.nun 45.maddesinde cezalar; h&uuml;rriyeti bağlayıcı cezalar ve
adli para cezaları olarak ikiye ayrılmıştır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
1-H&uuml;rriyeti Bağlayıcı Cezalar:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">H&uuml;rriyeti bağlayıcı cezalar, kanunda şu şekilde tasnife tabi
tutulmuştur.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">a) Ağırlaştırılmış m&uuml;ebbet hapis cezası</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">b) M&uuml;ebbet hapis cezası</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">c) S&uuml;reli hapis cezası</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">a) Ağırlaştırmış m&uuml;ebbet hapis cezası; h&uuml;k&uuml;ml&uuml;n&uuml;n hayatı boyunca
devam eder ve sıkı g&uuml;venlik rejimine g&ouml;re &ccedil;ektirilir. Bu cezaya h&uuml;k&uuml;ml&uuml;
olanlar, hi&ccedil;bir şekilde ceza infaz kurumunun dışında &ccedil;alıştırılmamakta ve
kendilerine izin verilmemekte, kurum i&ccedil; y&ouml;netmeliğinde belirtilenlerin dışında
herhangi bir spor faaliyetine katılamamakta ayrıca hi&ccedil;bir şekilde cezanın
infazına ara verilmemektedir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">b)M&uuml;ebbet hapis cezası; h&uuml;k&uuml;ml&uuml;n&uuml;n hayatı boyunca devam eder. Bu
cezada sıkı g&uuml;venlik rejimi uygulanmamaktadır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">c)S&uuml;reli hapis cezası; kanunda aksi belirtilmeyen hallerde bir
aydan az, yirmi yıldan fazla olamaz. H&uuml;kmedilen bir yıl ve daha az hapis
cezası, kısa s&uuml;reli hapis cezasıdır. Kısa s&uuml;reli hapis cezaları, belli
kriterler esas alınarak TCK.nun 50.maddesinde sayılan alternatif yaptırımlara
&ccedil;evrilebilmektedir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Kısa s&uuml;reli hapis cezası, su&ccedil;lunun kişiliğine, sosyal ve
ekonomik durumuna, yargılama s&uuml;recinde duyduğu pişmanlığa ve su&ccedil;un
işlenmesindeki &ouml;zelliklere g&ouml;re;</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">a)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Adl&icirc; para cezasına,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">b)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Mağdurun veya kamunun uğradığı
zararın aynen iade, su&ccedil;tan &ouml;nceki h&acirc;le getirme veya tazmin suretiyle, tamamen
giderilmesine,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">c)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; En az iki yıl s&uuml;reyle, bir
meslek veya sanat edinmeyi sağlamak amacıyla, gerektiğinde barınma imk&acirc;nı da
bulunan bir eğitim kurumuna devam etmeye,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">d)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Mahk&ucirc;m olunan cezanın
yarısından bir katına kadar s&uuml;reyle, belirli yerlere gitmekten veya belirli
etkinlikleri yapmaktan yasaklanmaya,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">e)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Sağladığı hak ve yetkiler
k&ouml;t&uuml;ye kullanılmak suretiyle veya gerektirdiği dikkat ve &ouml;zen y&uuml;k&uuml;ml&uuml;l&uuml;ğ&uuml;ne
aykırı davranılarak su&ccedil; işlenmiş olması durumunda; mahk&ucirc;m olunan cezanın
yarısından bir katına kadar s&uuml;reyle, ilgili ehliyet ve ruhsat belgelerinin geri
alınmasına, belli bir meslek ve sanatı yapmaktan yasaklanmaya,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">f)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Mahk&ucirc;m olunan
cezanın yarısından bir katına kadar s&uuml;reyle ve g&ouml;n&uuml;ll&uuml; olmak koşuluyla kamuya
yararlı bir işte &ccedil;alıştırılmaya,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&Ccedil;evrilebilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Su&ccedil; tanımında hapis cezası ile adl&icirc; para cezasının se&ccedil;enek
olarak &ouml;ng&ouml;r&uuml;ld&uuml;ğ&uuml; h&acirc;llerde, hapis cezasına h&uuml;kmedilmişse; bu ceza artık adl&icirc;
para cezasına &ccedil;evrilmez.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Daha &ouml;nce hapis cezasına mahk&ucirc;m edilmemiş olmak koşuluyla,
mahk&ucirc;m olunan otuz g&uuml;n ve daha az s&uuml;reli hapis cezası ile fiili işlediği
tarihte onsekiz yaşını doldurmamış veya altmışbeş yaşını bitirmiş bulunanların
mahk&ucirc;m edildiği bir yıl veya daha az s&uuml;reli hapis cezası, birinci fıkrada
yazılı se&ccedil;enek yaptırımlardan birine &ccedil;evrilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Taksirli su&ccedil;lardan dolayı h&uuml;kmolunan hapis cezası uzun s&uuml;reli de
olsa; bu ceza, diğer koşulların varlığı h&acirc;linde, birinci fıkranın (a) bendine
g&ouml;re adl&icirc; para cezasına &ccedil;evrilebilir. Ancak, bu h&uuml;k&uuml;m, bilin&ccedil;li taksir h&acirc;linde
uygulanmaz.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Uygulamada asıl mahk&ucirc;miyet, bu madde h&uuml;k&uuml;mlerine g&ouml;re &ccedil;evrilen
adl&icirc; para cezası veya tedbirdir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">H&uuml;k&uuml;m kesinleştikten sonra Cumhuriyet savcılığınca yapılan
tebligata rağmen otuz g&uuml;n i&ccedil;inde se&ccedil;enek yaptırımın gereklerinin yerine
getirilmesine başlanmaması veya başlanıp da devam edilmemesi h&acirc;linde, h&uuml;km&uuml;
veren mahkeme kısa s&uuml;reli hapis cezasının tamamen veya kısmen infazına karar
verir ve bu karar derh&acirc;l infaz edilir. Bu durumda, beşinci fıkra h&uuml;km&uuml;
uygulanmaz. Yani asıl mahk&ucirc;miyet, bu madde h&uuml;k&uuml;mlerine g&ouml;re &ccedil;evrilen adl&icirc; para
cezası veya tedbirdir değil, tamamen ya da kısmen infazına karar verilen
h&uuml;rriyeti bağlayıcı cezadır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">H&uuml;kmedilen se&ccedil;enek tedbirin h&uuml;k&uuml;ml&uuml;n&uuml;n elinde olmayan nedenlerle
yerine getirilememesi durumunda, h&uuml;km&uuml; veren mahkemece tedbir değiştirilir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">2.Adli Para Cezası:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></strong><span class="apple-converted-space"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></strong></span><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Adli para cezası, beş g&uuml;nden az, kanunda aksi
belirtilmeyen hallerde yediy&uuml;zotuz g&uuml;nden fazla olmamak &uuml;zere belirlenen tam
g&uuml;n sayısının, bir g&uuml;n karşılığı olarak takdir edilen miktar ile &ccedil;arpılması
suretiyle hesaplanan meblağın, h&uuml;k&uuml;ml&uuml; tarafından Devlet Hazinesine
&ouml;denmesinden ibarettir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">En az yirmi ve en fazla y&uuml;z T&uuml;rk Lirası olan bir g&uuml;n karşılığı
adl&icirc; para cezasının miktarı, kişinin ekonomik ve diğer şahs&icirc; h&acirc;lleri g&ouml;z &ouml;n&uuml;nde
bulundurularak takdir edilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Kararda, adl&icirc; para cezasının belirlenmesinde esas alınan tam g&uuml;n
sayısı ile bir g&uuml;n karşılığı olarak takdir edilen miktar ayrı ayrı g&ouml;sterilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">H&acirc;kim, ekonomik ve şahs&icirc; h&acirc;llerini g&ouml;z &ouml;n&uuml;nde bulundurarak,
kişiye adl&icirc; para cezasını &ouml;demesi i&ccedil;in h&uuml;km&uuml;n kesinleşme tarihinden itibaren
bir yıldan fazla olmamak &uuml;zere mehil verebileceği gibi, bu cezanın belirli
taksitler h&acirc;linde &ouml;denmesine de karar verebilir. Taksit s&uuml;resi iki yılı ge&ccedil;emez
ve taksit miktarı d&ouml;rtten az olamaz. Kararda, taksitlerden birinin zamanında
&ouml;denmemesi h&acirc;linde geri kalan kısmın tamamının tahsil edileceği ve &ouml;denmeyen
adl&icirc; para cezasının hapse &ccedil;evrileceği belirtilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Ceza ve G&uuml;venlik Tedbirlerinin İnfazı Hakkındaki Kanunda Adli
Para Cezası şu şekilde d&uuml;zenlenmiştir:</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; MADDE 106.-</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(1) Adl&icirc; para cezası, T&uuml;rk Ceza Kanununun 52 nci maddesinin
birinci fıkrasında belirtilen usule g&ouml;re tayin olunacak bir miktar paranın
Devlet Hazinesine &ouml;denmesinden ibarettir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(2) Adl&icirc; para cezasını i&ccedil;eren&nbsp; il&acirc;m Cumhuriyet Başsavcılığına
verilir. Cumhuriyet savcısı otuz g&uuml;n i&ccedil;inde adl&icirc; para cezasının &ouml;denmesi i&ccedil;in
h&uuml;k&uuml;ml&uuml;ye 20 nci maddenin &uuml;&ccedil;&uuml;nc&uuml; fıkrası uyarınca bir &ouml;deme emri tebliğ eder.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(3) H&uuml;k&uuml;ml&uuml;, tebliğ olunan &ouml;deme emri &uuml;zerine belli s&uuml;re i&ccedil;inde
adl&icirc; para cezasını &ouml;demezse, Cumhuriyet savcısının kararı ile &ouml;denmeyen kısma
karşılık gelen g&uuml;n miktarınca hapsedilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(4) &Ccedil;ocuklar hakkında h&uuml;kmedilen; adli para cezası ile hapis
cezasından &ccedil;evrilen adli para cezasının &ouml;denmemesi halinde, bu cezalar hapse
&ccedil;evrilemez. Bu takdirde onbirinci fıkra h&uuml;km&uuml; uygulanır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(5) Adl&icirc; para cezasının hapse &ccedil;evrileceği mahkeme il&acirc;mında
yazılı olmasa bile &uuml;&ccedil;&uuml;nc&uuml; fıkra h&uuml;km&uuml; Cumhuriyet Başsavcılığınca uygulanır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(6) H&uuml;k&uuml;mde, adl&icirc; para cezası takside bağlanmamış ise, bir aylık
s&uuml;re i&ccedil;inde adl&icirc; para cezasının &uuml;&ccedil;te birini &ouml;deyen h&uuml;k&uuml;ml&uuml;n&uuml;n isteği &uuml;zerine
geri kalan kısmının birer ay ara ile iki eşit taksitte &ouml;denmesine izin verilir.
İlk taksidin s&uuml;resinde &ouml;denmemesi h&acirc;linde, verilen ikinci takside ilişkin izin
h&uuml;k&uuml;ms&uuml;z kalır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(7) Adl&icirc; para cezası yerine &ccedil;ektirilen hapis s&uuml;resi&nbsp; &uuml;&ccedil;
yılı ge&ccedil;emez. Birden fazla h&uuml;k&uuml;mle adl&icirc; para cezalarına mahk&ucirc;miyet h&acirc;linde bu
s&uuml;re beş yılı ge&ccedil;emez.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(8) H&uuml;k&uuml;ml&uuml;, hapis yattığı g&uuml;nlerin dışındaki g&uuml;nlere karşılık
gelen parayı &ouml;derse hapisten &ccedil;ıkartılır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(9) T&uuml;rk Ceza Kanununun 50 nci maddesinin birinci fıkrasının (a)
bendi saklı kalmak &uuml;zere, adl&icirc; para cezasından &ccedil;evrilen hapsin infazı
ertelenemez ve bunun infazında koşullu salıverilme h&uuml;k&uuml;mleri uygulanamaz. Hapse
&ccedil;evrilmiş olmasına rağmen hak yoksunlukları bakımından esas alınacak olan adl&icirc;
para cezasıdır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(10) T&uuml;rk Ceza Kanununun 50 nci maddesinin birinci fıkrasının
(a) bendine g&ouml;re kısa s&uuml;reli hapis cezasından &ccedil;evrilen adl&icirc; para cezalarının
infazında, aynı maddenin altıncı ve yedinci fıkraları h&uuml;k&uuml;mleri saklıdır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(11) İnfaz edilen hapsin s&uuml;resi, adl&icirc; para cezasını tamamıyla
karşılamamış olursa, geri kalan adl&icirc; para cezasının tahsili i&ccedil;in il&acirc;m,
Cumhuriyet Başsavcılığınca mahallin en b&uuml;y&uuml;k mal memuruna verilir. Bu
makamlarca 6183 sayılı Amme Alacaklarının Tahsil Usul&uuml; Hakkında Kanuna g&ouml;re
kalan adl&icirc; para cezası tahsil edilir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
&nbsp; Tutuklu:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Hakkında tutulama kararı verilen kişiye tutuklu denir. Peki
tutuklama nedir?</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Tutuklama, Anayasada ve kanunda belirtilen koşullardan birinin
varlığı halinde, su&ccedil;luluğu hakkında kuvvetli belirti bulunan bir kişinin,
h&uuml;k&uuml;mden &ouml;nce, ihtiyari ve ge&ccedil;ici bir tedbir olarak, yargılamanın g&uuml;venli
y&uuml;r&uuml;mesine hizmet amacıyla bir tutukevine konulmak &uuml;zere hakimin kararıyla
h&uuml;rriyetinden mahrum edilmesidir. Kısa bir ifadeyle, su&ccedil; işlediğine dair hakkında
kuvvetli delil bulunan sanığın &ouml;zg&uuml;rl&uuml;ğ&uuml;n&uuml;n hakim kararıyla sınırlanmasıdır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Tutuklama, ceza değil bir tedbirdir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; Tutuklama nedenleri</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Ceza Muhakemesi Kanununda tutuklama nedenleri şu şekilde
sayılmıştır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; MADDE 100.</span></strong><span class="apple-converted-space" style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&ndash;</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(1) Kuvvetli su&ccedil; ş&uuml;phesinin varlığını g&ouml;steren olguların ve bir
tutuklama nedeninin bulunması halinde, ş&uuml;pheli veya sanık hakkında tutuklama
kararı verilebilir. İşin &ouml;nemi, verilmesi beklenen ceza veya g&uuml;venlik tedbiri
ile &ouml;l&ccedil;&uuml;l&uuml; olmaması halinde, tutuklama kararı verilemez.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(2) Aşağıdaki hallerde bir tutuklama nedeni var sayılabilir:</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">a) Ş&uuml;pheli veya sanığın ka&ccedil;ması, saklanması veya ka&ccedil;acağı
ş&uuml;phesini uyandıran somut olgular varsa.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">b) Ş&uuml;pheli veya sanığın davranışları;</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">1. Delilleri yok etme, gizleme veya değiştirme,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">2. Tanık, mağdur veya başkaları &uuml;zerinde baskı yapılması
girişiminde bulunma,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Hususlarında kuvvetli ş&uuml;phe oluşturuyorsa.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(3) Aşağıdaki su&ccedil;ların işlendiği hususunda kuvvetli ş&uuml;phe
sebeplerinin varlığı halinde, tutuklama nedeni var sayılabilir:</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">a) 26.9.2004 tarihli ve 5237 sayılı T&uuml;rk Ceza Kanununda yer
alan;</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">1. Soykırım ve insanlığa karşı su&ccedil;lar (madde 76, 77, 78),</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">2. Kasten &ouml;ld&uuml;rme (madde 81, 82, 83),</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">3. İşkence (madde 94, 95)</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">4. Cinsel saldırı (birinci fıkra hari&ccedil;, madde 102),</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">5. &Ccedil;ocukların cinsel istismarı (madde 103),</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">6. Uyuşturucu veya uyarıcı madde imal ve ticareti (madde 188),</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">7. Su&ccedil; işlemek amacıyla &ouml;rg&uuml;t kurma (iki, yedi ve sekizinci
fıkralar hari&ccedil;, madde 220),</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">8. Devletin G&uuml;venliğine Karşı Su&ccedil;lar (madde 302, 303, 304, 307,
308),</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">9. Anayasal D&uuml;zene ve Bu D&uuml;zenin İşleyişine Karşı Su&ccedil;lar (madde
309, 310, 311, 312, 313, 314, 315),</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">b) 10.7.1953 tarihli ve 6136 sayılı Ateşli Silahlar ve Bı&ccedil;aklar
ile Diğer Aletler Hakkında Kanunda tanımlanan silah ka&ccedil;ak&ccedil;ılığı (madde 12)
su&ccedil;ları.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">c) 18.6.1999 tarihli ve 4389 sayılı Bankalar Kanununun 22 nci
maddesinin (3) ve (4) numaralı fıkralarında tanımlanan zimmet su&ccedil;u.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">d) 10.7.2003 tarihli ve 4926 sayılı Ka&ccedil;ak&ccedil;ılıkla M&uuml;cadele
Kanununda tanımlanan ve hapis cezasını gerektiren su&ccedil;lar.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">e) 21.7.1983 tarihli ve 2863 sayılı K&uuml;lt&uuml;r ve Tabiat
Varlıklarını Koruma Kanununun 68 ve 74 &uuml;nc&uuml; maddelerinde tanımlanan su&ccedil;lar.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">f) 31.8.1956 tarihli ve 6831 sayılı Orman Kanununun 110 uncu
maddesinin d&ouml;rt ve beşinci fıkralarında tanımlanan kasten orman yakma su&ccedil;ları.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(4) Sadece adl&icirc; para cezasını gerektiren veya hapis cezasının
&uuml;st sınırı bir yıldan fazla olmayan su&ccedil;larda tutuklama kararı verilemez.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
H&uuml;k&uuml;ml&uuml;:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Yapılan soruşturma ve yargılama sonunda hakimin uyuşmazlık
konusunu esastan halleden ve yargılamayı sona erdiren kararına h&uuml;k&uuml;m, b&ouml;yle bir
mahkumiyet h&uuml;km&uuml; alan kimseye de h&uuml;k&uuml;ml&uuml; denir. Kısaca hakkında kesinleşmiş
ceza mahkumiyeti bulunan kimsedir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
H&uuml;k&uuml;m&ouml;zl&uuml; (H&uuml;kmen Tutuklu)</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Yapılan soruşturma ve yargılama neticesi hakkında mahkumiyet
kararı verilen, ancak kararla ilgili temyiz s&uuml;resi dolmayan veya kararı temyiz
edilmekle birlikte onaylanmayan tutuklulara h&uuml;k&uuml;m&ouml;zl&uuml; ya da h&uuml;kmen tutuklu
denir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Sanıklar hakkında verilen mahkumiyet kararları kesinleşmedik&ccedil;e
infaz edilemeyeceği i&ccedil;in h&uuml;kmen tutuklular h&uuml;k&uuml;ml&uuml; stat&uuml;s&uuml;nde sayılmazlar.
Bunun doğal sonucu olarak koşullu salıverme h&uuml;k&uuml;mlerinden yararlanamazlar.
H&uuml;k&uuml;ml&uuml;lerle aynı yerde barındırılmamaktadırlar.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
Tehlikeli H&uuml;k&uuml;ml&uuml;</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Tehlikeli h&uuml;k&uuml;ml&uuml;lerin tanımı Avrupa Konseyi Bakanlar
Komitesinin R(82)17 sayılı Tavsiye Kararında yapılmıştır. Buna g&ouml;re; &ldquo;İşlediği
su&ccedil;un nitelik ve icra şekli g&ouml;z &ouml;n&uuml;ne alındığında; toplum i&ccedil;in ciddi bir
tehlike oluşturan ve cezaevi g&uuml;venlik ve nizamını ihlal edebileceği y&ouml;n&uuml;nde
kuvvetli delil bulunan h&uuml;k&uuml;ml&uuml;d&uuml;r.&rdquo;</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Tehlikelilik kavramı, kişiye, işlenen su&ccedil;a, i&ccedil;inde yaşanılan
toplumun yaşam kriterlerine g&ouml;re değişiklik g&ouml;sterebilecektir. Ancak
uygulamada, cezaevindeki yaşama uyum g&ouml;stermeyenler, firar etme riski
bulunanlar, personele ve h&uuml;k&uuml;ml&uuml;lere karşı saldırganlık g&ouml;sterenler,
psikopatlar, intihar etme eğilimi olanlar genellikle tehlikeli su&ccedil;lu
&ouml;zellikleri taşıyan insanlardır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Y&uuml;ksek &ouml;l&ccedil;&uuml;de ka&ccedil;ma tehlikesi ortaya koyan veya cebir
kullanacağından korkulan veya intihar etme riski g&ouml;steren bir kişi &ldquo;Tehlikeli&rdquo;
su&ccedil;lu olarak tanımlanmaktadır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Ceza ve G&uuml;venlik Tedbirlerinin İnfazı Hakkındaki Kanunun
9.Maddesinin 3. Fıkrasına g&ouml;re &ldquo;Eylem ve tutumları nedeniyle tehlikeli halde
bulunanlar&rdquo; y&uuml;ksek g&uuml;venlikli kapalı ceza infaz kurumuna g&ouml;nderilirler.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
V-İLAMIN İNCELENMESİ VE İNFAZ İŞLEMLERİ</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp;
&nbsp; &nbsp; İnfaz, s&ouml;zl&uuml;kteki anlamıyla yerine getirme demektir. Hukuk
terminolojisinde infaz, mahkeme kararının yerine getirilmesini ifade
etmektedir. İnfaz edilecek mahkeme kararına ilam denmektedir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
İlamın incelenmesinde dikkat edilecek konular</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">1)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
İlamın kesinleşme şerhinin bulunup bulunmadığı, hangi h&uuml;k&uuml;ml&uuml; i&ccedil;in ve hangi
cezanın infazı i&ccedil;in ilamın Cumhuriyet başsavcılığına verildiği kaydı kontrol
edilmelidir.Kesinleşmemiş ilamlar infaz edilmemelidir. Mahkeme ilamında bir
sanık i&ccedil;in birden fazla cezaya veya birden fazla h&uuml;k&uuml;ml&uuml; i&ccedil;in ayrı ayrı
cezalara h&uuml;kmedilmiş olabilir. Bu nedenle kararın kesinleşme şerhinde h&uuml;km&uuml;n
kesinleştiği tarih ile hangi sanık i&ccedil;in hangi cezanın infaza verildiği a&ccedil;ık bir
şekilde yazılmış olmalıdır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">2)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; TCK. 51. Maddesi gereğince
cezanın ertelenip ertelenmediği kontrol edilmelidir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">3)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; TCK. 50. maddesinde ge&ccedil;en 30
g&uuml;n ve daha az hapis cezası ile daha &ouml;nce hapis cezasına mahkum edilmemiş olmak
koşuluyla fiili işlediği tarihte on sekiz yaşını doldurmamış veya altmış beş
yaşını bitirmiş bulunanların mahkum edildiği bir yıl veya daha az s&uuml;reli hapis
cezasının aynı maddenin birinci fıkrasında yazılı ceza ya da tedbirlerden
birine &ccedil;evrilip &ccedil;evrilmediği incelenmelidir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">4)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; H&uuml;k&uuml;mde TCK.nun 66 ve 73.
maddeleri gereğince dava zamanaşımı ve şikayetten vazge&ccedil;me şeklinde bir kayıt
bulunup bulunmadığı kontrol edilmelidir. İlamda bu maddeler uygulanmış ise
evrak ilamat defterine<span class="apple-converted-space">&nbsp;</span><strong>kaydedilmemelidir</strong>.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">5)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; H&uuml;k&uuml;ml&uuml;n&uuml;n ilamda yazılı su&ccedil;tan
tutuklu kalıp kalmadığı ve bu su&ccedil;tan tutuklu kalmış ise tutuklulukta ge&ccedil;irdiği
s&uuml;renin şartla tahliye s&uuml;resini karşılayıp karşılamadığı kontrol edilmelidir.
Eğer karşılıyor ise mahkemesinden şartla tahliye kararı alınmalı ve ilamat
defterindeki kayıt kapatılarak mahkemesine g&ouml;nderilmelidir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">6)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; İlamın ceza zamanaşımına
uğrayıp uğramadığı kontrol edilmelidir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">7)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; H&uuml;k&uuml;mde hata olup olmadığı
kontrol edilmelidir. &Ouml;rneğin adli para cezası ya da h&uuml;rriyeti bağlayıcı cezanın
yanlış hesaplanması durumunda evrakın ilamat defterine kaydı yapılmamalı ve kanun
yoluna başvurulmalıdır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">8)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Fiilin su&ccedil; olmaktan &ccedil;ıkartılıp
&ccedil;ıkartılmadığı, affa uğrayıp uğramadığı incelenmelidir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
HAPİS CEZALARININ İNFAZI</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp; &nbsp; &nbsp; Hapis cezalarının
infazında g&ouml;zetilecek ilkeler</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Hapis cezalarının infaz rejimi, aşağıda g&ouml;sterilen temel
ilkelere dayalı olarak d&uuml;zenlenir:</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">a-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="apple-converted-space">&nbsp;</span><strong>H&uuml;k&uuml;ml&uuml;ler</strong>&nbsp;
ceza&nbsp; infaz&nbsp; kurumlarında&nbsp; g&uuml;venli&nbsp; bir&nbsp; bi&ccedil;imde&nbsp;
ve ka&ccedil;malarını &ouml;nleyecek tedbirler alınarak<span class="apple-converted-space">&nbsp;</span><strong>d&uuml;zen, g&uuml;venlik ve disiplin &ccedil;er&ccedil;evesinde</strong>&nbsp;
tutulurlar.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">b-&nbsp;&nbsp;&nbsp;&nbsp; Ceza infaz kurumlarında h&uuml;k&uuml;ml&uuml;lerin
d&uuml;zenli bir yaşam s&uuml;rd&uuml;rmeleri sağlanır. H&uuml;rriyeti bağlayıcı cezanın zorunlu
kıldığı h&uuml;rriyetten yoksunluk, insan onuruna saygının&nbsp; korunmasını
sağlayan madd&icirc; ve manev&icirc; koşullar altında &ccedil;ektirilir. H&uuml;k&uuml;ml&uuml;lerin, Anayasada
yer alan diğer<span class="apple-converted-space">&nbsp;</span><strong>hakları</strong>, infazın temel
ama&ccedil;ları saklı kalmak &uuml;zere, bu Kanunda &ouml;ng&ouml;r&uuml;len kurallar uyarınca<span class="apple-converted-space">&nbsp;</span><strong>kısıtlanabilir</strong>.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">c-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Cezanın infazında h&uuml;k&uuml;ml&uuml;n&uuml;n
iyileştirilmesi hususunda m&uuml;mk&uuml;n olan ara&ccedil; ve olanaklar kullanılır.
H&uuml;k&uuml;ml&uuml;n&uuml;n&nbsp; kanun, t&uuml;z&uuml;k ve y&ouml;netmeliklerle tanınmış haklarının
dokunulmazlığını sağlamak &uuml;zere cezanın infazında ve iyileştirme &ccedil;abalarında<span class="apple-converted-space">&nbsp;</span><strong>kanun&icirc;lik
ve hukuka uygunluk ilkeleri esas alınır.</strong></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">d-&nbsp;&nbsp;&nbsp;&nbsp; İyileştirmeye gereksinimleri olmadığı
saptanan h&uuml;k&uuml;ml&uuml;lere ilişkin infaz rejiminde, bu h&uuml;k&uuml;ml&uuml;lerin kişilikleriyle
orantılı<span class="apple-converted-space">&nbsp;</span><strong>bireyselleştirilmiş programlara</strong><span class="apple-converted-space">&nbsp;</span>yer verilmesine &ouml;zen g&ouml;sterilir&nbsp;
ve bu hususlar y&ouml;netmeliklerde d&uuml;zenlenir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">e-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Cezanın infazında<span class="apple-converted-space">&nbsp;</span><strong>adalet
esaslarına</strong><span class="apple-converted-space">&nbsp;</span>uygun
hareket edilir. Bu maksatla ceza infaz kurumları kanun, t&uuml;z&uuml;k ve
y&ouml;netmeliklerin verdiği yetkilere dayanarak nitelikli elemanlarca denetlenir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">f-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;Ceza infaz
kurumlarında h&uuml;k&uuml;ml&uuml;lerin<span class="apple-converted-space">&nbsp;</span><strong>yaşam hakları ile beden ve ruh
b&uuml;t&uuml;nl&uuml;klerini korumak &uuml;zere her t&uuml;rl&uuml; koruyucu tedbi</strong>rin
alınması zorunludur.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">g-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; H&uuml;k&uuml;ml&uuml;n&uuml;n infazın amacına
uygun olarak<span class="apple-converted-space">&nbsp;</span><strong>kanun, t&uuml;z&uuml;k ve y&ouml;netmeliklerin
belirttiği h&uuml;k&uuml;mlere uyması zorunludur.</strong></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">h-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Kanunlarda g&ouml;sterilen tutum,
davranış ve eylemler ile kurum d&uuml;zenini ihl&acirc;l edenler hakkında Kanunda
belirtilen<span class="apple-converted-space">&nbsp;</span><strong>disiplin cezaları uygulanır.</strong><span class="apple-converted-space">&nbsp;</span>Cezalara, Kanunda belirtilen merciler,
s&uuml;relerine uygun olarak h&uuml;kmederler. Cezalara karşı savunma ve itirazlar da
Kanunun g&ouml;sterdiği mercilere yapılır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; İyileştirmede
başarı &ouml;l&ccedil;&uuml;t&uuml;</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(1) Hapis cezalarının infazında h&uuml;k&uuml;ml&uuml;lerin iyileştirilmeleri
amacını g&uuml;den programların başarısı,<span class="apple-converted-space">&nbsp;</span><strong>elde ettikleri yeni tutum ve becerilerle
orantılı olarak</strong><span class="apple-converted-space">&nbsp;</span>&ouml;l&ccedil;&uuml;l&uuml;r.
Bunun i&ccedil;in iyileştirme &ccedil;abalarına y&ouml;nelik olarak h&uuml;k&uuml;ml&uuml;n&uuml;n<span class="apple-converted-space">&nbsp;</span><strong>istekli</strong><span class="apple-converted-space"><strong>&nbsp;</strong></span>bulunması teşvik edilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">(2)<span class="apple-converted-space">&nbsp;</span><strong>Hapis cezasının, kendisinde var olan
zararlı etki yapıcı niteliğini m&uuml;mk&uuml;n olduğu &ouml;l&ccedil;&uuml;de</strong><span class="apple-converted-space"><strong>&nbsp;</strong></span>azaltacak bi&ccedil;imde d&uuml;zenlenecek
programlar, us&ucirc;ller, ara&ccedil;lar ve zihniyet doğrultusunda yerine getirilmesi
esasına uyulur. İyileştirme ara&ccedil;ları h&uuml;k&uuml;ml&uuml;n&uuml;n sağlığını ve kişiliğine olan
saygısını korumasını sağlayacak us&ucirc;l ve esaslara g&ouml;re uygulanır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Hapis
Cezalarının İnfazı &nbsp;işlemleri</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp;
&nbsp; &nbsp; Kararı veren mahkeme, h&uuml;km&uuml;n kesinleşmesini m&uuml;teakip<span class="apple-converted-space">&nbsp;</span><strong>bir
hafta i&ccedil;inde</strong><span class="apple-converted-space">&nbsp;</span>aynı
yerde bulunan Cumhuriyet Başsavcılığına kararı g&ouml;ndermelidir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
Kararı veren mahkemenin yanında bulunan Cumhuriyet Başsavcılığının yargı
&ccedil;evresinde oturan h&uuml;k&uuml;ml&uuml;ye ait ilamın infazı İşlemi:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;1-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></strong><span class="apple-converted-space"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></strong></span><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">H&uuml;k&uuml;ml&uuml; ilamdaki su&ccedil; nedeniyle
tutuklu ya da başka bir su&ccedil; nedeniyle aynı yerde h&uuml;k&uuml;ml&uuml; değilse:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">H&uuml;k&uuml;ml&uuml; hakkında ka&ccedil;acağı ya da ka&ccedil;acağına dair ş&uuml;phenin
bulunmaması ve &uuml;&ccedil; yıldan az hapis cezasının bulunması halinde; h&uuml;k&uuml;ml&uuml;n&uuml;n
mahkeme kararında belirtilen adresine<span class="apple-converted-space">&nbsp;</span><strong>&ccedil;ağrı kağıdı</strong><span class="apple-converted-space">&nbsp;</span>g&ouml;nderilmelidir. &Ccedil;ağrı kağıdı &uuml;zerine
gelen ve CGTİHK nun 17. maddesi uyarınca erteleme talebinde bulunmayan h&uuml;k&uuml;ml&uuml;
hakkında m&uuml;ddetname tanzim edilerek cezaevine g&ouml;nderilmelidir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Şu hallerde de h&uuml;k&uuml;ml&uuml; hakkında<span class="apple-converted-space">&nbsp;</span><strong>yakalama</strong><span class="apple-converted-space">&nbsp;</span>m&uuml;zekkeresi &ccedil;ıkartılmalıdır:</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">a)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Cezanın 3 yıldan fazla hapis
olması. Burada dikkat edilmesi gereken konu, mahkeme h&uuml;km&uuml;nde mahsubu &ouml;ng&ouml;r&uuml;len
tutululukta ve nezarette ge&ccedil;en s&uuml;relerin ilam geldiğinde hesaplanarak bakiye
ceza &uuml;zerinden &ouml;deme emri, &ccedil;ağrı kağıdı veya yakalama m&uuml;zekkeresi &ccedil;ıkartılması
gerektiğidir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">b)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; H&uuml;k&uuml;ml&uuml;n&uuml;n ka&ccedil;ması ya da
ka&ccedil;acağı yolunda ş&uuml;pheler bulunması,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">c)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Usul&uuml;ne uygun &ccedil;ağrı kağıdına
rağmen 10 g&uuml;n i&ccedil;inde Cumhuriyet başsavcılığına başvurmamış olması,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">d)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Cezasının infazı ertelenmiş
olup da erteleme s&uuml;resi sonunda h&uuml;k&uuml;ml&uuml;n&uuml;n Cumhuriyet başsavcılığına
başvurmamış olması.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Yakalama m&uuml;zekkeresi doğrultusunda yakalanan h&uuml;k&uuml;ml&uuml;yle ilgili
m&uuml;ddetname d&uuml;zenlenerek cezaevine g&ouml;nderilir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;2-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></strong><span class="apple-converted-space"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></strong></span><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">H&uuml;k&uuml;ml&uuml;, infaz edilecek ilam
nedeniyle cezaevinde tutuklu olarak bulunuyorsa;</span></strong><span class="apple-converted-space" style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">m&uuml;ddetname d&uuml;zenlenerek ilam evrakı cezaevine
g&ouml;nderilmelidir. Cezaevinde m&uuml;ddetnamenin bir sureti h&uuml;k&uuml;ml&uuml;ye tebliğ
edilmelidir. Bu durumda kişi tutuklu stat&uuml;s&uuml;nden &ccedil;ıkmış h&uuml;k&uuml;ml&uuml; stat&uuml;s&uuml;ne
ge&ccedil;miştir. Bu nedenle kişinin tutuklu defterinde bulunan kaydı kapatılmalı,
h&uuml;k&uuml;ml&uuml; defterine kaydı yapılmalıdır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;3-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></strong><span class="apple-converted-space"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></strong></span><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">H&uuml;k&uuml;ml&uuml;, başka bir su&ccedil;tan dolayı
cezaevinde h&uuml;k&uuml;ml&uuml; olarak bulunuyorsa;</span></strong><span class="apple-converted-space" style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">g&ouml;revli mahkemesinden alınacak toplama
kararıyla cezalar toplanıp yeniden m&uuml;ddetname d&uuml;zenlenerek buna g&ouml;re infaz
işlemi yapılmalıdır. Bu hususta h&uuml;k&uuml;m vermek yetkisi<span class="apple-converted-space">&nbsp;</span><strong>en
fazla cezaya</strong><span class="apple-converted-space">&nbsp;</span>h&uuml;kmetmiş
olan mahkemeye, bu durumda birden &ccedil;ok mahkeme yetkili ise<span class="apple-converted-space">&nbsp;</span><strong>en
son h&uuml;km&uuml;</strong><span class="apple-converted-space"><strong>&nbsp;</strong></span>vermiş
olan mahkemeye; h&uuml;k&uuml;mlerden biri doğrudan doğruya b&ouml;lge adliye mahkemesi
tarafından verilmiş ise<span class="apple-converted-space">&nbsp;</span><strong>b&ouml;lge adliye mahkemesine</strong>,
Yargıtay tarafından verilmiş ise<span class="apple-converted-space">&nbsp;</span><strong>Yargıtay&rsquo;a</strong><span class="apple-converted-space">&nbsp;</span>aittir. Toplanan b&uuml;t&uuml;n cezalara ait
ilamlar, m&uuml;ddetnamenin altına not olarak yazılmalıdır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;4-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></strong><span class="apple-converted-space"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></strong></span><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">H&uuml;k&uuml;ml&uuml;n&uuml;n, başka bir su&ccedil;tan
dolayı cezaevinde tutuklu bulunması halinde izlenecek y&ouml;ntem:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Kural olarak ilamların infazı, tutuklama kararlarının infazından
&ouml;nce gelir. Bu durumda ilamın infazına başlanıp tutukluluk hali durdurulur.
İleride yanlışlıklara sebebiyet verilmemesi i&ccedil;in Cezaevi m&uuml;d&uuml;rl&uuml;ğ&uuml;nce ilgili
mahkemeye durum bildirilmelidir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Yukarıdaki olasılıklardan birine g&ouml;re cezaevine alınan h&uuml;k&uuml;ml&uuml;
i&ccedil;in Cumhuriyet Savcısınca cezaevi m&uuml;d&uuml;rl&uuml;ğ&uuml;ne aşağıdaki yazı yazılır:</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">1-&nbsp;&nbsp;&nbsp;&nbsp; M&uuml;ddetnameye g&ouml;re cezanın infazı</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">2-&nbsp;&nbsp;&nbsp;&nbsp; Yiyecek bordrosu yapılarak h&uuml;k&uuml;ml&uuml;ye
tebliği: (Altı aydan fazla h&uuml;rriyeti bağlayıcı cezaya mahkum edilenler i&ccedil;in
altı ayda bir,altı aydan az h&uuml;rriyeti bağlayıcı cezaya mahkum edilenler i&ccedil;in
salıverilecekleri tarihten bir hafta &ouml;nce d&uuml;zenlenmeli)</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">3-&nbsp;&nbsp;&nbsp;&nbsp; H&uuml;k&uuml;ml&uuml;n&uuml;n askerlikle ilişkisi var
ise tahliyesinde serbest bırakılmayarak askerlik şubesi başkanlığına teslim
edilmek &uuml;zere jandarma komutanlığına teslimi,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">4-&nbsp;&nbsp;&nbsp;&nbsp; Bir yıl ya da daha fazla h&uuml;rriyeti
bağlayıcı cezaya mahkum edilen<span class="apple-converted-space">&nbsp;</span><strong>reşit h&uuml;k&uuml;ml&uuml;ler</strong><span class="apple-converted-space"><strong>&nbsp;</strong></span>i&ccedil;in<span class="apple-converted-space">&nbsp;</span><strong>vasi</strong><span class="apple-converted-space">&nbsp;</span>atanması yolunda yazı yazılması
istenir. Vasi atamada yetkili merci h&uuml;k&uuml;ml&uuml;n&uuml;n cezaevine alınmadan &ouml;nceki en
son ikametgahı sulh hukuk mahkemesidir. Vasi atanması i&ccedil;in Cezaevi m&uuml;d&uuml;rl&uuml;ğ&uuml;,
iki ay i&ccedil;inde bu yer mahkemesine Cumhuriyet savcılığı aracılığı ile yazı
yazmalı ve yetkili sulh hukuk mahkemesince resen araştırma yapılarak vasi
atanmalıdır.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
H&uuml;k&uuml;ml&uuml;n&uuml;n kararı veren mahkemenin yanında bulunan Cumhuriyet Başsavcılığının
yargı &ccedil;evresi dışında oturması halinde h&uuml;rriyeti bağlayıcı cezanın infazı
İşlemi:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
&nbsp;&nbsp;</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İlam oturulan yerin yargı &ccedil;evresinde bulunan C.Savcılığına
postayla ve mutlaka iadeli taahh&uuml;tl&uuml; mektup ile g&ouml;nderilmelidir. İnfaz
işlemleri bu Cumhuriyet başsavcılığınca y&uuml;r&uuml;t&uuml;l&uuml;r.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İlamı alan Cumhuriyet Savcılığı, yukarıda a&ccedil;ıklandığı gibi ilam
&uuml;zerinde gerekli incelemeleri yaptıktan sonra ilamı, ilamat defterine
kaydetmeli ve ilamat numarasını ilamı g&ouml;nderen Cumhuriyet başsavcılığına
bildirmelidir. Ayrıca ilamın akıbeti hakkında d&uuml;zenli aralıklarla ilamı
g&ouml;nderen Cumhuriyet başsavcılığına bilgi vermelidir.<strong>&nbsp;&nbsp;</strong></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
M&uuml;kerrirlere &Ouml;zg&uuml; İnfaz Rejimi:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp; &nbsp; &nbsp; &nbsp;
&nbsp; &nbsp;&nbsp;<strong>Tekerr&uuml;r:</strong><span class="apple-converted-space">&nbsp;</span>Daha &ouml;nce işlenen su&ccedil;a ilişkin
mahkumiyet kararının kesinleşmesinden sonra tekerr&uuml;re esas yeni bir su&ccedil;
işlenmesidir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Sonradan işlenen bir su&ccedil; nedeniyle tekerr&uuml;r h&uuml;k&uuml;mlerinin
uygulanabilmesi i&ccedil;in bu su&ccedil;un; &ouml;nceden işlenen bir su&ccedil;tan dolayı beş yıldan
fazla s&uuml;reyle hapis cezasına mahkumiyet halinde cezanın infaz edildiği tarihten
itibaren beş yıl i&ccedil;inde işlenmesi; &ouml;nceden işlenen bir su&ccedil;la ilgili beş yıl ya
da daha az s&uuml;reli hapis ya da adli para cezasına mahkumiyet halinde ise bu
cezanın infaz edildiği tarihten itibaren &uuml;&ccedil; yıl i&ccedil;inde sonraki su&ccedil;un işlenmesi
gerekir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Ceza Ve G&uuml;venlik Tedbirlerinin İnfazına Dair Kanunun 108.
maddesinde m&uuml;kerrirlere &ouml;zg&uuml; infaz rejimi ve denetimli serbestlik tedbiri şu
şekilde d&uuml;zenlenmiştir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Tekerr&uuml;r h&acirc;linde işlenen su&ccedil;tan dolayı mahk&ucirc;m olunan;</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">a) Ağırlaştırılmış m&uuml;ebbet hapis cezasının otuzdokuz yılının,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">b) M&uuml;ebbet hapis cezasının otuz&uuml;&ccedil; yılının,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">c) S&uuml;reli hapis cezasının d&ouml;rtte &uuml;&ccedil;&uuml;n&uuml;n,</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İnfaz kurumunda iyi h&acirc;lli olarak &ccedil;ekilmesi durumunda, koşullu
salıverilmeden yararlanılabilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Tekerr&uuml;r nedeniyle koşullu salıverme s&uuml;resine eklenecek miktar,
tekerr&uuml;re esas alınan cezanın en ağırından fazla olamaz.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">İkinci defa tekerr&uuml;r h&uuml;k&uuml;mlerinin uygulanması durumunda, h&uuml;k&uuml;ml&uuml;
koşullu salıverilmez.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">H&acirc;kim, m&uuml;kerrir hakkında cezanın infazının tamamlanmasından
sonra başlamak ve bir yıldan az olmamak &uuml;zere denetim s&uuml;resi belirler.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Tekerr&uuml;r dolayısıyla belirlenen denetim s&uuml;resinde, koşullu salıverilmeye
ilişkin h&uuml;k&uuml;mler uygulanır.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">H&acirc;kim, m&uuml;kerrir hakkında denetim s&uuml;resinin uzatılmasına karar
verebilir. Denetim s&uuml;resi en fazla beş yıla kadar uzatılabilir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">G&ouml;r&uuml;ld&uuml;ğ&uuml; &uuml;zere, 765 sayılı T&uuml;rk Ceza Kanunundan farklı
olarak&nbsp; 5237 sayılı T&uuml;rk Ceza Kanununda verilen cezaların tekerr&uuml;r
nedeniyle artırılması d&uuml;zenlenmemiş ve bu husus<span class="apple-converted-space">&nbsp;</span><strong>infaz
aşamasından dikkate alınarak</strong><span class="apple-converted-space">&nbsp;</span>ayrı
bir koşullu salıverme h&acirc;li d&uuml;zenlenmiştir.</span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">Koşullu Salıverme:</span></strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;"></span></p>
<p style="line-height: 11.9pt;"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Koşullu
salıverme,</span></strong><span class="apple-converted-space"><strong><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">&nbsp;</span></strong></span><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">hakkında
h&uuml;kmedilen hapis cezasının bir kısmını cezaevinde iyi halli olarak ge&ccedil;iren
h&uuml;k&uuml;ml&uuml;n&uuml;n, yasada &ouml;n g&ouml;r&uuml;len diğer koşulların da varlığı halinde bihakkın
tahliye tarihinden &ouml;nce salıverilmesidir.</span></p>
<p style="line-height: 11.9pt;"><span style="font-size: 8pt; font-family: Georgia, serif; color: #333333;">H&uuml;k&uuml;ml&uuml;n&uuml;n koşullu salıverilmeden faydalanabilmesi i&ccedil;in,&nbsp;
ceza infaz kurumlarının d&uuml;zen ve g&uuml;venliği amacıyla konulmuş kurallara
i&ccedil;tenlikle<span class="apple-converted-space">&nbsp;</span><strong>uyması</strong>,<span class="apple-converted-space">&nbsp;</span><strong>haklarını</strong><span class="apple-converted-space">&nbsp;</span>iyi niyetle kullanması,<span class="apple-converted-space">&nbsp;</span><strong>y&uuml;k&uuml;ml&uuml;l&uuml;klerini</strong><span class="apple-converted-space">&nbsp;</span>eksiksiz yerine getirmesi ve uygulanan
iyileştirme programlarına g&ouml;re de toplumla<span class="apple-converted-space">&nbsp;</span><strong>b&uuml;t&uuml;nleşmeye</strong><span class="apple-converted-space">&nbsp;</span>hazır olduğunun disiplin kurulunun
g&ouml;r&uuml;ş&uuml; alınarak idare kurulunca saptanmış bulunması gerekmektedir. (md. 89).</span></p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">&nbsp;</p>
<h1><span style="text-decoration: underline; font-size: 12pt;">1987&prime;den 2013&prime;e Anayasa değişiklikleri</span></h1>
<p class="MsoNormal">12 Eyl&uuml;l 1982. T&uuml;rkiye&rsquo;de askeri darbeyle sivil otorite
g&ouml;revden uzaklaştırıldı. Yerine silahlı g&uuml;ce dayanan otorite geldi. Koşullar
neydi, nasıl oluştu? Hep tartışıldı. Bu tartışma daha s&uuml;receğe benziyor.</p>
<p class="MsoNormal">Her darbe y&ouml;netiminde olduğu gibi 12 Eyl&uuml;l y&ouml;netimi de kendi
hukuksal sistemini oluşturdu. Yapılan 1982 Anayasası, 7 Kasım 1982 tarihindeki
halkoylamasında y&uuml;zde 91.17 &rdquo;Evet&rdquo; oyuyla kabul edildi. Bu orana nasıl ulaşıldığı
da tartışılagelen bir durum. Sonunda askeri y&ouml;netim tarafından yap(tır)ılan
anayasa 9 Kasım 1982&prime;de y&uuml;r&uuml;rl&uuml;ğe girdi. Anayasa toplam 177 madde ve 16 ge&ccedil;ici
maddeden oluşuyordu. Eleştirilen &ccedil;ok y&ouml;n&uuml; vardı, ancak maddeler kendi kendi
b&uuml;t&uuml;nl&uuml;ğ&uuml; i&ccedil;inde ve &ouml;ng&ouml;r&uuml;len yapısal oluşum i&ccedil;inde d&uuml;zenlenmişti.</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">1982 Anayasal sisteminin daha beşinci yılında ilk değişiklik
g&uuml;ndeme geldi. Aradan ge&ccedil;en 25 yılda, &nbsp;1982 Anayasası&rsquo;nın 106 maddesi ve 4
ge&ccedil;ici maddesi ile bir kez de başlangı&ccedil; metni değiştirildi. Eklenen &uuml;&ccedil; ge&ccedil;ici
maddeden ikisi daha sonra metinden &ccedil;ıkarıldı. Bu değişikliklerin biri Anayasa
Mahkemesi&rsquo;nce iptal edildi.&nbsp;Yapılan değişiklikler, 1982 Anayasası&rsquo;nın
y&uuml;zde 60&prime;nın yeniden d&uuml;zenlenmesi niteliğindeydi.</p>
<p class="MsoNormal">T&uuml;rkiye&rsquo;de bug&uuml;n yeni bir anayasa metni hazırlanıyor. Bu
ama&ccedil;la kurulan uzlaşma komisyonu, ilk değişikliğin 25. yıld&ouml;n&uuml;nde yeni bir
anayasal metin ortaya koyma &ccedil;abasında. Bu &ccedil;abanın sonucu, sivillerin toplumsal
uzlaşma k&uuml;lt&uuml;r&uuml;n&uuml;n nereye kadar g&ouml;t&uuml;r&uuml;lebileceğinin de bir &ouml;rneği olacak.
Bug&uuml;nk&uuml; &ccedil;alışmaların sonunda &rdquo;toplumsal uzlaşı&rdquo; mı ortaya konulacak, yoksa yeni
bir &rdquo;anayasa tartşması&rdquo; mı başlayacak, bunu zaman g&ouml;sterecek.</p>
<p class="MsoNormal">1982 Anayasası&rsquo;nda farklı iktidarlar d&ouml;neminde yapılan
değişiklikler ş&ouml;yle sıralanabilir:</p>
<p class="MsoNormal"><strong>Siyasi yasaklar kalktı </strong></p>
<p class="MsoNormal">1982 Anayasası&rsquo;ndaki ilk değişiklik anayasanın kabul&uuml;nden 5
yıl sonra yapıldı.14 Mayıs 1984 tarihinde TBMM&rsquo;de kabul edilen bu değişiklik 17
Mayıs 1987&prime;de Resmi Gazete&rsquo;de yayımlandı. İktidarda ANAP vardı ve Başbakan
Turgut &Ouml;zal&rsquo;dı.<br />
Bu d&uuml;zenlemeyle&nbsp;Anayasa&rsquo;nın 67, 75. ve 175. maddeleri yeniden
d&uuml;zenleniyor, Ge&ccedil;ici 4. madde ise y&uuml;r&uuml;rl&uuml;kten kaldırılıyordu. 67. maddenin
değiştirilmesiyle &nbsp;se&ccedil;men olma yaşı 21&prime;den 19&prime;a indirildi; 75. madde
yeniden d&uuml;zenlenerek milletvekili sayısı 400&prime;den 450&prime;ye y&uuml;kseltildi.</p>
<p class="MsoNormal">12 Eyl&uuml;l &ouml;ncesi siyasi partilerin ve liderlerine siyaset
yasağı getiren Ge&ccedil;ici 4. madde, bu konuda yapılan halkoylamasıyla y&uuml;r&uuml;rl&uuml;kten
kaldırıldı. Bu, 12 Eyl&uuml;l yasak&ccedil;ı yaklaşımına y&ouml;nelik bir tavır olarak da
yorumlanıyordu. B&ouml;ylece, S&uuml;leyman Demirel, B&uuml;lent Ecevit, Necmettin Erbakan ve
Alparslan T&uuml;rkeş gibi liderlerin de aralarında bulunduğu kişiler ve siyasi
partilerine y&ouml;nelik siyaset yasağı sona erdi.</p>
<p class="MsoNormal"><strong>Radyo ve TV yayıncılığına serbestlik </strong></p>
<p class="MsoNormal">Anayasa&rsquo;daki ikinci değişiklik 8 Temmuz 1993 tarihinde
yapıldı. &nbsp;İktidarda bu kez DYP-SHP koalisyon h&uuml;k&uuml;meti vardı ve Başbakanlık
koltuğunda Tansu &Ccedil;iller oturuyordu.</p>
<p class="MsoNormal">Radyo ve televizyon yayıncılığıyla ilgili 133. maddesi
yeniden d&uuml;zenlendi. B&ouml;ylece, radyo ve televizyon istasyonları kurmak ve
işletmek, yasal d&uuml;zenlemelerle oluşturulacak şartlar &ccedil;er&ccedil;evesinde serbest hale
getirildi.</p>
<p class="MsoNormal"><strong><br />
<strong>Milletvekili sayısı arttı </strong></strong></p>
<p class="MsoNormal">Anayasa&rsquo;daki 23 Temmuz 1995 tarihinde yapılan &uuml;&ccedil;&uuml;nc&uuml;
değişiklik geniş kapsamlıydı. Anayasanın başlangı&ccedil; metninin yanı sıra 33, 53,
67, 68, 69, 75, 84, 85, 93, 127, 135, 149. ve 171. maddeleri yeniden
d&uuml;zenlendi, 52. madde y&uuml;r&uuml;rl&uuml;kten kaldırıldı.<br />
Bu değişiklik kapsamında daha &ouml;nce 19 olan se&ccedil;menlik yaşı 18&prime;e indirildi.
Siyasal partilerin yurt dışı faaliyetleri, kadın ve gen&ccedil;lik kolları gibi yan
&ouml;rg&uuml;t kurmalarını yasaklayan h&uuml;k&uuml;mler kaldırıldı. Y&uuml;ksek &ouml;ğretim elemanlarına,
yasayla d&uuml;zenlenecek &ccedil;er&ccedil;evede, siyasal &nbsp;partilere &uuml;ye olabilme imkanı
sağlandı. Y&uuml;ksek &ouml;ğretimde kurumlarındaki &ouml;ğrencilere de siyasal partilere &uuml;ye
olma hakkı .</p>
<p class="MsoNormal">1987&prime;deki değişiklikle 400&prime;den 450&prime;ye &ccedil;ıkarılan milletvekili
sayısı bu kez 550&prime;ye y&uuml;kseltildi. &nbsp;&rdquo;Milletvekilliğinin nasıl sona ereceği&rdquo;
konusundaki tartışmalı h&uuml;k&uuml;m yeniden d&uuml;zenlendi. Yasama yılı başlangıcı Eyl&uuml;l
ayından Ekim&rsquo;e alındı.&nbsp;Anayasa&rsquo;nın sendikalara siyasal faaliyet yasağını
d&uuml;zenleyen 52. maddesi y&uuml;r&uuml;rl&uuml;kten kaldırıldı. B&ouml;ylece, &nbsp;sendikacıların
siyasal faaliyette bulunmalarının yanı sıra sendikaların ve siyasal partilerin
birbirlerine destek vermesinin &ouml;n&uuml;ndeki engel kaldırıldı.</p>
<p class="MsoNormal"><strong>DGM&rsquo;lerin &uuml;ye yapısı</strong></p>
<p class="MsoNormal">D&ouml;rd&uuml;nc&uuml; değişiklik 18 Haziran 1999 damgasını taşıyor.<br />
Anayasa&rsquo;nın 143. maddesinde yeniden d&uuml;zenlenerek DGM&rsquo;lerde yer alan asker
&uuml;yelerin yerine sivil yargı&ccedil;ların atanması sağlandı. Bu d&uuml;zenleme, daha sonraki
s&uuml;re&ccedil;te kaldırılacak olan DGM&rsquo;lerin sivilleşterilmesi anlamına geliyordu.</p>
<p class="MsoNormal"><strong>&Ouml;zelleştirmeye anayasal g&uuml;vence</strong></p>
<p class="MsoNormal">Tarih 13 Ağustos 1999&prime;yi g&ouml;steriyordu. Bu d&ouml;nemde iktidarda
DSP-MHP-ANAP koalisyon h&uuml;k&uuml;meti vardı ve B&uuml;lent Ecevit başbakan koltuğundaydı.<br />
1982 Anayasasına beşinci değişiklik yapıldı. Bu kez Anayasanın 47, 125. ve 155.
maddeleri yeniden d&uuml;zenlendi.&nbsp;47. maddede yapılan değişiklikle
&rdquo;&ouml;zelleştirme&rdquo; kavramı Anayasal g&uuml;venceye alındı. Bu kapsamda, kamu t&uuml;zel
kişilerinin m&uuml;lkiyetindeki işletme ve varlıkların &ouml;zelleştirilmesine y&ouml;nelik
ilke ve y&ouml;ntemlerin yasayla d&uuml;zenleneceği h&uuml;kme bağlandı.<br />
Kamu hizmeti imtiyaz s&ouml;zleşme ve şartlaşmalarında doğacak uyuşmazlıklarda da
tahkim yolu a&ccedil;ıldı.<br />
Anayasanın 155. maddesinde değişiklik yapılarak, imtiyaz şartlaşma ve
s&ouml;zleşmeleri, Danıştay&rsquo;ın inceleme yapacağı konular arasından &ccedil;ıkarıldı.
D&uuml;zenlemeyle Danıştay bu durumlarda sadece g&ouml;r&uuml;ş bildirebilecek konuma
getirildi. Bu,&nbsp;1924 Anayasası&rsquo;nda benimsenen sisteme d&ouml;n&uuml;lmesi anlamına
geliyordu.</p>
<p class="MsoNormal"><strong>AB m&uuml;ktesebatına uyum</strong></p>
<p class="MsoNormal">Anayasada yapılan altıncı değişiklik 3 Ekim 2001 tarihini
taşıyordu. AB m&uuml;ktesebatına uyum &ccedil;alışmaları kapsamındaki bu d&uuml;zelemeler, aynı
zamanda Anayasada yapılan en kapsamlı değişiklik oldu. &nbsp;Bu &ccedil;er&ccedil;evede
Anayasa&rsquo;nın başlangı&ccedil; metninin yanı sıra 13, 14, 19, 20, 21, 22, 23, 26, 28,
31, 33, 34, 36, 38, 40, 41, 46, 49, 51, 55, 65, 66, 67, 69, 74, 86, 87, 89, 94,
100, 118. ve 149. maddeler ile Ge&ccedil;ici 15. maddesinde d&uuml;zenlemeler yapıldı.<br />
Değişiklikler kapsamında, g&ouml;zaltına alma ya da tutuklanmada kişilerin hakim
&ouml;n&uuml;ne &ccedil;ıkarılma s&uuml;releri AİHS&rsquo;ne uyumlu hale getirildi. Ş&uuml;phelilerin en ge&ccedil; 48
saatte, toplu işlenen su&ccedil;larda ise en &ccedil;ok 4 g&uuml;nde hakim &ouml;n&uuml;ne &ccedil;ıkarılması
kuralı getirildi.<br />
&rdquo;&Ouml;zel Hayatın Gizliliği&rdquo; başlıklı madde yeniden d&uuml;zenlendi. Bu kapsamda
herkese, &ouml;zel hayatına ve aile hayatına saygı g&ouml;sterilmesini isteme hakkı
tanındı. Yazılı emir olmadık&ccedil;a kimsenin konutuna girilemeyeceği, arama
yapılamayacağı ve buradaki eşyaya el konulamayacağı anayasal kural olarak
d&uuml;zenlendi.<br />
&rdquo;Haberleşme H&uuml;rriyeti&rdquo; başlıklı 22. maddede yeniden d&uuml;zenlenerek, usul&uuml;ne g&ouml;re
verilmiş hakim kararı ve yazılı emir olmadık&ccedil;a, haberleşmenin engellenemeyeceği
ve haberleşmenin gizliliğine dokunulamayacağı h&uuml;km&uuml; getirildi.</p>
<p class="MsoNormal">D&uuml;ş&uuml;nce ve ifade &ouml;zg&uuml;rl&uuml;ğ&uuml;n&uuml;n sınırları genişletildi. Milli
g&uuml;venlik, kamu d&uuml;zeni, kamu g&uuml;venliği ve b&ouml;l&uuml;nmez b&uuml;t&uuml;nl&uuml;ğ&uuml;n korunması
ama&ccedil;larıyla, d&uuml;ş&uuml;nceyi a&ccedil;ıklama ve yayma h&uuml;rriyetinin sınırlanabileceği şartı
Anayasa&rsquo;ya konuldu.<br />
Herkesin derneklere &uuml;ye olma ya da &uuml;yelikten &ccedil;ıkma h&uuml;rriyetine sahip olduğu
y&ouml;n&uuml;ndeki h&uuml;k&uuml;m anayasa metnine konuldu. Toplantı ve g&ouml;steri y&uuml;r&uuml;y&uuml;ş&uuml;
d&uuml;zenleceklere izin almayı zorunlu tutan d&uuml;zenleme kaldırıldı. Kanuna aykırı
şeklide elde edilmiş bulguların delil kabul edilemeyeceği kuralı getirildi.<br />
Kamulaştırmada, ger&ccedil;ek karşılıkların &ouml;denmesi ve &ouml;demede gecikme halinde faiz
y&ouml;n&uuml;nden bireylerin zarara uğramamalarına ilişkin h&uuml;k&uuml;mler getirildi.
Anayasanın 49. maddesinde yapılan değişiklikle devlete, &ccedil;alışanların yanı sıra
işsizleri de koruma g&ouml;revi verecek şekilde d&uuml;zenlendi. Asgari &uuml;cretin
tespitinde, &ccedil;alışanların ge&ccedil;im şartları ile &uuml;lkenin ekonomik durumunun
g&ouml;z&ouml;n&uuml;nde bulundurulması h&uuml;km&uuml; getirildi.<br />
&rdquo;Se&ccedil;im kanunlarında yapılan değişiklikler, y&uuml;r&uuml;rl&uuml;ğe girdiği tarihten itibaren
bir yıl i&ccedil;inde yapılacak se&ccedil;imlerde uygulanmaz&rdquo; h&uuml;km&uuml; 67. madde metnine
eklendi. Parti kapatmadaki&nbsp;69. maddede d&uuml;zenlenen &rdquo;odak olma&rdquo; hali
tanımlandı. Bir partinin temelli kapatılmasının, sadece Anayasa&rsquo;nın 68/4.
fıkrasındaki eylemlerin odağı haline gelmiş olması şartıyla m&uuml;mk&uuml;n kuralı
getirildi. Temelli kapatılan bir partinin kurucularının ve her kademedeki
y&ouml;neticilerinin 5 yıl s&uuml;reyle yeni bir partinin kurucusu, y&ouml;neticisi ve
deneticisi olamayacağı h&uuml;km&uuml; getirildi. Siyasi partiler i&ccedil;in kapatmanın yanı
sıra Hazine yardımından yoksun bırakılma yaptırımı da anayasla d&uuml;zelemeye
alındı.<br />
Parti kapatma daha zor hale getirildi. Anayasa Mahkemesinin Anayasa
değişikliklerinin iptali ve siyasi partileri kapatmada, 5&prime;te 3 &ccedil;oğunlukla karar
vermesi kuralı konuldu.<br />
T&uuml;rk vatandaşlarına tanınan TBMM&rsquo;ye dilek&ccedil;e ile başvurma hakkı, karşılıklılık
esası g&ouml;zetilmek kaydıyla yabancılara da tanındı.&nbsp;Milli G&uuml;venlik Kurulu
b&uuml;nyesine Başbakan yardımcıları ve Adalet Bakanı da dahil edildi; kurul
kararlarının tavsiye niteliğinde olduğu metne işlendi.<br />
Anayasa&rsquo;nın ge&ccedil;ici 15. maddesinin son fıkrası y&uuml;r&uuml;rl&uuml;kten kaldırıldı.</p>
<p class="MsoNormal"><strong>Referandumdan d&ouml;nd&uuml;ren değişiklik</strong></p>
<p class="MsoNormal">10. Cumhurbaşkanı Ahmet Necdet Sezer&rsquo;in, anayasa değişikliği
paketindeki milletvekillerinin &ouml;zl&uuml;k ve emeklilik haklarına ilişkin maddeyi
referanduma g&ouml;t&uuml;rme kararı aldı. 86. maddedeki bu d&uuml;zenleme i&ccedil;in 21 Kasım 2001
tarihinde yeniden Anayasa değişikliğine gidildi. Bu maddede değişiklik yapan
yasa 1 Aralık 2001&prime;de Resmi Gazete&rsquo;de yayımlanarak y&uuml;r&uuml;rl&uuml;ğe girdi. Bu
kapsamda, Sezer&rsquo;in &ouml;nceki değişiklik metnini referanduma g&ouml;t&uuml;rme kararının
konusu ortadan kaldırıldı.</p>
<p class="MsoNormal"><strong>Sekizinci değişiklik</strong></p>
<p class="MsoNormal">1982 Anayasası&rsquo;ndaki sekizinci değişiklik 26 Aralık 2002
tarihinde yapıldı. Bu kapsamda Anayasanın 76. ve 78. maddeleri yeniden
d&uuml;zenlendi. &rdquo;Milletvekilliği Se&ccedil;ilme Yeterliliği&rdquo; başlıklı maddedeki
değişiklikle milletvekili se&ccedil;ilemeyecek şartlar arasında sayılan &rdquo;ideolojik
veya anarşik eylemlere&rdquo; ifadesi &rdquo;ter&ouml;r eylemlerine&rdquo; olarak değiştirildi.</p>
<p class="MsoNormal">TBMM &uuml;yeliğinde boşalma durumunda, Meclis kararıyla ara
se&ccedil;ime gidilebileceği; ancak bir ilin veya se&ccedil;im &ccedil;evresinin TBMM&rsquo;de &uuml;yesinin
kalmaması halinde, boşalmayı takip eden 90 g&uuml;nden sonraki ilk Pazar g&uuml;n&uuml; ara
se&ccedil;im yapılması h&uuml;kme bağlandı.</p>
<p class="MsoNormal"><strong>-&Ouml;l&uuml;m cezası kaldırıldı</strong></p>
<p class="MsoNormal">T&uuml;rkiye&rsquo;de AK Parti iktidardaydı ve başbakan koltuğunun yeni
sahibi Recep Tayyip Erdoğan&rsquo;dı.<br />
AB m&uuml;ktesebatına uyum d&uuml;zenlemeleri kapsamındaki bir başka anayasa değişikliği
paketi 7 Mayıs 2004 tarihinde kabul edildi.&nbsp;Anayasa&rsquo;nın 10, 15, 17, 30,
38, 87, 90, 131. ve 160. maddelerinde değiştirlidi, 143. madde kaldırıldı.<br />
Bu d&uuml;zenlemeler kapsamında, kadınlar ve erkeklerin eşit haklara sahip olduğu,
10. maddede yapılan değişiklik ile Anayasa&rsquo;ya konuldu. Devletin, bu eşitliğin
yaşama ge&ccedil;mesini sağlamakla y&uuml;k&uuml;ml&uuml; olduğu da metinde yer aldı. Basın ara&ccedil;ları
anayasal koruma altına alındı. &nbsp;&nbsp;Anayasa&rsquo;nın, 38. maddesinde yapılan
yeni d&uuml;zenlemeyle &ouml;l&uuml;m cezası kaldırıldı.<br />
Temel hak ve &ouml;zg&uuml;rl&uuml;kler konusunda uluslararası anlaşmalar ile kanunların
&ccedil;elişmesi durumundaki uyuşmazlıkta, hangisinin &ouml;ncelikli olacağı anayasal
d&uuml;zenlemeye alındı. Bu kapsamda, Anayasanın 90. maddesine bir fıkra eklenerek,
uyuşmazlıklarda, uluslararası anlaşma h&uuml;k&uuml;mlerinin esas alınacağı ilkesi
getirildi.<br />
Y&Ouml;K&rsquo;e Genelkurmay&rsquo;dan temsilci verilmesi uygulamasına son verildi.<br />
Anayasanın 160. maddesindeki &nbsp;&rdquo;Silahlı Kuvvetler elinde bulunan devlet
mallarının TBMM adına denetlenmesi usulleri, milli savunma hizmetlerinin
gerektirdiği gizlilik esaslarına uygun olarak kanunla d&uuml;zenlenir&rdquo; fıkrası
metninden &ccedil;ıkarıldı.<br />
1999&prime;daki t&uuml;m&uuml;yle sivil yargı&ccedil;lardan oluşacak şekilde d&uuml;zenlenen DGM&rsquo;ler bu kez
kaldırıldı.</p>
<p class="MsoNormal"><strong>RT&Uuml;K değişikliği</strong></p>
<p class="MsoNormal">Anayasadaki onuncu değişiklik 21 Haziran 2005 tarihinde
yapıldı. Bu kapsamda, Anayasanın 133. maddesi yeniden d&uuml;zenlenerek, Radyo ve
Televizyon &Uuml;st Kurulu&rsquo;na (RT&Uuml;K) &uuml;ye se&ccedil;imine ilişkin h&uuml;k&uuml;mler yeniden
d&uuml;zenlendi.</p>
<p class="MsoNormal"><strong>Onbirinci değişiklik</strong></p>
<p class="MsoNormal">1982 Anayasası&rsquo;ndaki onbirinci değişiklik 29 Ekim 2005
tarihinde yapldı.<br />
Bu d&uuml;zenleme kapsamında Anayasanın 130, 160, 161, 162. ve 163. maddeleri
değiştirildi. Sayıştay denetim kapsamı genişletildi; b&uuml;t&ccedil;enin hazırlanması,
uygulanması ve kontrol&uuml;ne ilişkin s&uuml;re&ccedil; yeniden d&uuml;zenlendi.&nbsp;Anayasanın
162. maddesindeki &rdquo;genel ve katma b&uuml;t&ccedil;e tasarıları&rdquo; ibaresi &rdquo;merkezi y&ouml;netim
b&uuml;t&ccedil;e tasarısı&rdquo; şeklinde değiştirildi.</p>
<p class="MsoNormal"><strong>Se&ccedil;ilme yaşı 25&prime;e indi </strong></p>
<p class="MsoNormal">1982 Anayasası&rsquo;nda yapılan onikinci değişiklik 13 Ekim 2006
tarihini taşıyordu. Anayasanın 76. maddesinde yapıla değişiklikle se&ccedil;ilme yaşı
30&prime;dan &nbsp;25&prime;e indirildi.</p>
<p class="MsoNormal"><strong>On&uuml;&ccedil;&uuml;nc&uuml; değişiklik</strong></p>
<p class="MsoNormal">1982 Anayasası&rsquo;ndaki on&uuml;&ccedil;&uuml;nc&uuml; değişiklik 10 Mayıs 2007
tarihinde yapıldı.<br />
Bu &ccedil;er&ccedil;evede, Anayasaya Ge&ccedil;ici 17. madde eklendi. Bu d&uuml;zenlemeyle, 22 Temmuz
2007&prime;de yapılacak se&ccedil;imde; bağımsız adayların isimlerinin birleşik oy
pusulasında yer almasına y&ouml;nelik d&uuml;zenlemeler yapılıyordu.</p>
<p class="MsoNormal"><strong>Cumhurbaşkanını halkın se&ccedil;mesi</strong></p>
<p class="MsoNormal">1982 Anayasası&rsquo;nda 31 Mayıs 2007 tarihinde yapılan 14.
değişiklik de &ouml;nemli d&uuml;zenlemeler getiriyordu. Bu kapsamda, Anayasanın 77, 79,
96, 101. ve 102. maddeleri yeniden d&uuml;zenlendi; Anayasaya Ge&ccedil;ici 18. ve Ge&ccedil;ici
19. madde eklendi.<br />
Milletvekili se&ccedil;iminin 5 yıl yerine 4 yılda bir yapılması
&ouml;ng&ouml;r&uuml;ld&uuml;.&nbsp;TBMM&rsquo;nin, &nbsp;se&ccedil;imler dahil yapacağı t&uuml;m işlerde, &uuml;ye
tamsayısının 3&prime;te 1&prime;i (184) ile toplanması &nbsp;kurala bağlandı. Meclis&rsquo;in,
Anayasa&rsquo;da başkaca bir h&uuml;k&uuml;m yoksa toplantıya katılanların salt &ccedil;oğunluğu ile
karar vermesi, ancak karar yeter sayısının hi&ccedil;bir şekilde &uuml;ye tamsayısının 4&prime;te
1&prime;inin bir fazlasından az olamayacağı h&uuml;km&uuml; getirildi.<br />
Cumhurbaşkanı se&ccedil;iminde de k&ouml;kl&uuml; değişikliğe gidiliyordu. Cumhurbaşkanının 5+5
yıllık g&ouml;rev s&uuml;resiyle ve halk tarafından se&ccedil;ilmesi kuralı getirildi. Bu
se&ccedil;imin nasıl yapılacağına ilişkin d&uuml;zenlemeler ve buna ilişkin usul ve
esasları d&uuml;zenleme konusanda YSK&rsquo;ya verilen yetkiler de anayasa değişikliğinde
yer alıyordu.</p>
<p class="MsoNormal">Anayasa&rsquo;nın, &rdquo;Se&ccedil;im kanunlarında yapılacak değişikliklerin,
y&uuml;r&uuml;rl&uuml;ğe girdikleri tarihten itibaren 1 yıl i&ccedil;inde uygulanamayacağına&rdquo; ilişkin
maddesinin, Cumhurbaşkanı se&ccedil;iminde dikkate alınmaması h&uuml;kme bağlandı.
Cumhurbaşkanı se&ccedil;imine ilişkin getirilen yeni d&uuml;zenlemelerin 11. Cumhurbaşkanı
se&ccedil;iminde uygulanmasını &ouml;ng&ouml;r&uuml;l&uuml;yordu. Bu d&uuml;zenlemeler halkoyuna sunuldu.</p>
<p class="MsoNormal"><strong>Onbeşinci değişiklik</strong></p>
<p class="MsoNormal">Anayasa&rsquo;daki 15. değişiklik 16 Ekim 2007&prime;da
ger&ccedil;ekleştirildi. Bu, bir bakıma, daha &ouml;nceki değişiklik ve ardından oluşan
yeni parlamentonun yeni cumhurbaşkanını se&ccedil;mesiyle ka&ccedil;ınılmaz hale gelmişti. Bu
kapsamda, &nbsp;&rdquo;Se&ccedil;im kanunlarında yapılacak değişikliklerin 11. Cumhurbaşkanı
se&ccedil;iminde uygulanması&rdquo;na imkan sağlayan Ge&ccedil;ici 18. madde ile &rdquo;Cumhurbaşkanı
se&ccedil;imine ilişkin getirilen yeni kuralın 11. Cumhurbaşkanı se&ccedil;iminde de
uygulanmasını&rdquo; &ouml;ng&ouml;ren Ge&ccedil;ici 19. madde Anayasa metninden &ccedil;ıkarıldı.</p>
<p class="MsoNormal"><strong>Anayasa Mahkemesi iptal etti</strong></p>
<p class="MsoNormal">1982 Anayasası&rsquo;nın 10. maddesi 9 Şubat 2008 tarihinde
değiştirildi. &rdquo;&Uuml;niversitelerde t&uuml;rbanı serbest bırakan d&uuml;zenleme&rdquo; olarak da
nitelenen değişiklik kapsamında, &rdquo;devlet organları ve idare makamlarının, b&uuml;t&uuml;n
işlemlerinde olduğu gibi her t&uuml;rl&uuml; kamu hizmetlerinden yararlanılmasında kanun
&ouml;n&uuml;nde eşitlik ilkesine uygun olarak hareket etmek zorunda olduğu&rdquo; kurala
bağlanıyordu. Anayasa 42. maddede yapılan değişiklikle ise y&uuml;ksek &ouml;ğretimde
baş&ouml;rt&uuml;s&uuml;n&uuml;n serbest bırakılmasına ilişkin h&uuml;k&uuml;m kabul edilerek, kanunda a&ccedil;ık&ccedil;a
yazılı olmayan herhangi bir sebeple, kimsenin y&uuml;ksek &ouml;ğrenim hakkını
kullanmaktan mahrum edilemeyeceği belirtildi.<br />
Yapılan bu değişiklikler Anayasa Mahkemesi&rsquo;nce iptal edildi</p>
<p class="MsoNormal"><strong>Darbe y&ouml;netimine yargı yolu</strong></p>
<p class="MsoNormal">1982 Anayasası&rsquo;nda yapılan 17. ve son değişiklik 7 Mayıs
2010 tarihli kanunla yapıldı. Bu d&uuml;zenlemeler, 12 Eyl&uuml;l 1980 askeri
m&uuml;dahalesinin 30&prime;uncu yılında halk oylamasına sunularak kabul edildi.<br />
Bu değişiklikler&nbsp;1982 Anayasası&rsquo;nın 23 maddesi ile Ge&ccedil;ici 15, 18 ve 19.
maddelerini kapsıyordu. Anayasanın Ge&ccedil;ici 15. Maddesi&rsquo;nin y&uuml;r&uuml;rl&uuml;kten
kaldırılması 12 Eyl&uuml;l darbesi y&ouml;neticilerine yargı yolunun a&ccedil;ılması anlamına
geliyordu. Sendikal yaşam, ekonomi ve sosyal konulara ilişkin d&uuml;zenlemeler
Anayasanın&nbsp;10, 20, 23, 41, 51, 53, 54, 74, 84, 94, 125, 128, 129, 144,
145, 146, 147, 148, 149, 156, 157, 159, 166. madelerini kapsıyordu.<br />
Yapılan değişikliklerdeki bazı h&uuml;k&uuml;mler Anayasa Mahkemesince iptal edildi.
Anayasa değişikliği ise &nbsp;12 Eyl&uuml;l 2010 tarihinde halkoyuna sunuldu ve
kabul edildi.<br />
&ndash;<br />
<strong>Kaynaklar: TBMM kayıtları, &rdquo;551.vekil&rdquo; arşivi, s&uuml;reli yayınlar</strong></p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal"><strong><span style="text-decoration: underline;">Anayasal Bilgiler
(Soru Cevaplar): </span></strong></p>
<p>&bull; 1-Osmanlı Devletinin y&ouml;netim bi&ccedil;imi 1876 anayasası &ouml;ncesinde nasıldır?
Mutlak monarşi</p>
<p>2-T&uuml;rk Hukuk sisteminde ilk anayasal girişimin adı nedir?Senedd-i ittifak</p>
<p>3-Osmanlı Devletinin ilk anayasası hangisidir? 1876 Kanun-i Esasi</p>
<p>4-Egemenliğin millete ait olduğu,ilk kez hangi anayasa ile kabul
edilmiştir?1921 Anayasası.</p>
<p>5-Laiklik ilkesi anayasamıza ilk kez ne zaman girmiştir? 1937(1924
anayasasında yapılan değişiklikle)</p>
<p>6-Devletin dini İslam&rsquo;dır ibaresi ne zaman &ccedil;ıkartılmıştır?1928(1924
anayasasında yapılan değişiklikle)</p>
<p>7&Ccedil;ok partili siyasi hayat ilk kez hangi anayasa d&ouml;neminde başlamıştı?1924</p>
<p>8-Hangi hallerde ve kim tarafından se&ccedil;imlerin ertelenmesine karar
verilebilir? Savaş hali/TBMM</p>
<p>9-TBMM ve yerel y&ouml;netimler se&ccedil;imleri ka&ccedil; yılda bir yapılır? 5</p>
<p>10-S&uuml;resi dolmadan meclis se&ccedil;imlerine kim karar verir? TBMM</p>
<p>11-Meclis &ccedil;alışmalarını hangi d&uuml;zenlemeye bağlı olarak y&uuml;r&uuml;t&uuml;r? Meclis i&ccedil;
t&uuml;z&uuml;ğ&uuml;</p>
<p>12-Yasama dokunulmazlığı kaldırılan milletvekili nereye m&uuml;racaat edebilir?
Anayasa mahkemesi</p>
<p>13-Yasama sorumsuzluğunun kapsamı nelerden ibarettir? :Oy,s&ouml;z ve d&uuml;ş&uuml;nce</p>
<p>14-T&uuml;rkiye&rsquo;de uygulanan genel se&ccedil;im barajı y&uuml;zde ka&ccedil;tır? 10</p>
<p>15-T&uuml;rkiye&rsquo;de yapılan se&ccedil;imlerin denetimi ve g&ouml;zetimini sağlayan kuruluş
kimdir? Y&uuml;ksek se&ccedil;im kurulu</p>
<p>16-Ara se&ccedil;imlere hangi hallerde gidilir? TBMM &uuml;yeliğinin %5&rsquo;ini boşalması
Bir ilin veya se&ccedil;im &ccedil;evresinin TBMM hi&ccedil; &uuml;yesinin kalmaması.</p>
<p>17-Yasama dokunulmazlığını kaldıran karar organının adı nedir? Anayasa
mahkemesi</p>
<p>18-Genel se&ccedil;imlere ne kadar s&uuml;re kala/ s&uuml;re ge&ccedil;medik&ccedil;e ara se&ccedil;im yapılamaz?
1 yıl kala/30 ay ge&ccedil;medik&ccedil;e</p>
<p>19-Milletvekilinin se&ccedil;imden &ouml;nce veya sonra işlediği ileri s&uuml;ren bir su&ccedil;
nedeniyle tutuklanamamasına,sorguya &ccedil;ekilememesine,yargılanamaması na ne ad
verilir? Yasama dokunulmazlığı</p>
<p>20-Millet vekilliğini d&uuml;ş&uuml;ren halleri maddeleyiniz? İstifa,**&uuml;m ve gaiplik,
Milletvekili se&ccedil;ilmeye engel bir su&ccedil;tan h&uuml;k&uuml;m giyme, Mecliz &ccedil;alışmalarına izinsiz
ve &ouml;z&uuml;rs&uuml;z 5 birleşim g&uuml;n&uuml; katılmama, Milletvekilliği g&ouml;revi ile bağdaşmayan
bir işi s&uuml;rd&uuml;rmekte ısrar etme</p>
<p>21-TBMM&rsquo;nin h&uuml;k&uuml;meti denetleme yollarını yazynız? Soru,Gensoru,Meclis
araştırması,Meclis soruşturması</p>
<p>22-Meclis denetim yollarından hangisi h&uuml;k&uuml;metin siyasi sorumluluğunu
doğurur? Gensoru ve meclis soruşturması</p>
<p>24-TMBB&rsquo;yi doğrudan toplantıya &ccedil;ağırabilecek olan kişiler?
Cumhurbaşkanı/Meclis başkanı</p>
<p>25-Cumhurbaşkanına kim vekalet eder? Meclis başkanı</p>
<p>26-Meclis başkanı kim tarafından se&ccedil;ilir? TBMM</p>
<p>27-TBMM toplantı ve karar yeter sayısı hangisinde sırasıyla doğru
verilmiştir? Meclisin 3/1 ile toplanır ve salt &ccedil;oğunlukla karar verir.Ancak
karar yeter sayısı meclis &uuml;ye sayısının 4/1 altında olamaz.</p>
<p>28-Y&uuml;r&uuml;tme işlevini &uuml;stlenen kuruluşları yazınız? Cumhurbaşkanı/Bakanlar
kurulu</p>
<p>29-&ldquo;Meclis h&uuml;k&uuml;meti sisteminden vazge&ccedil;ilerek parlementer sisteme ge&ccedil;ilmiş ve
iki başlı y&uuml;r&uuml;tme bi&ccedil;imi benimsenmiştir.&rdquo;yukarıdaki değişiklik hangi anayasayla
yapılmıştır? 1924 Anayasası.</p>
<p>32-Cumhurbaşkanının istisnai ceza sorumluluğu dışındadır? Vatana ihanet</p>
<p>33-Genelkurmay Başkanlığı hangisine karşı sorumludur? Başbakan</p>
<p>34-TBMM genel se&ccedil;imlerinden &ouml;nce &ccedil;ekilen bakanlar hangileridir?
Adalet,İ&ccedil;işleri,Ulaştırma bakanlıkları</p>
<p>35-Devlet denetleme kurumu kime bağlıdır.Hangi alanları denetleyemez?
Cumhurbaşkanlığına,Askeri ve Adli kurumları</p>
<p>36-Ulusal g&uuml;venlik politikaların oluşturulmasında h&uuml;k&uuml;mete yardımcı olan
kuruluş? MGK(Milli G&uuml;venlik Kurulu)</p>
<p>37-Bakanlıkla ilgili &ouml;nemli bilgiler oluşturunuz? Başbakanın &ouml;nerisi &uuml;zerine
Cumhurbaşkanı tarafından atanır ve g&ouml;revden alınırlar. Bakanlar kurulu oy
birliği ile karar alır.<br />
Bir bakan en fazla bir bakana vekalet edebilir. Y&uuml;ce divana giden bakanın
g&ouml;revi sona erer. Gensoru yoluyla bakanların siyasi sorumluluğuna gidilebilir.</p>
<p>38-Kanun h&uuml;km&uuml;nde kararname &ccedil;ıkarma kim tarafından kime verilir? TBMM
tarafından Bakanlar kuruluna verilir.</p>
<p>39-Kanun h&uuml;km&uuml;nde kararnameler genel olarak ne zaman y&uuml;r&uuml;rl&uuml;ğe girer? Resmi
gazetede yayımlandıkları g&uuml;n.</p>
<p>40-Kuvvetler birliğini oluşturan unsurlar nelerdir?Ve kimler trf. Kullanılır?
Yasama&mdash;TBMM Y&uuml;r&uuml;tme&ndash;Cumhurbaşkanı/Bakanlar kurulu Yargı&mdash;Bağımsız T&uuml;rk
mahkemeleri<br />
41-Y&uuml;ksek mahkemeleri yazınız? Anayasa mahkemesi,Danıştay,Yargıtay,As keri
Yargıtay,Askeri y&uuml;ksek İdare mahkemesi,uyuşmazlık mahkemesi. (Sayıştay/YSK
Y&uuml;ksek mahkeme değildir)</p>
<p>42-&ldquo;Hakim ve savcılar azlolunamazlar,kendileri istemedik&ccedil;e anayasada
g&ouml;sterilen yaştan &ouml;ne emekliye ayrılamazlar&rdquo;.Yukarıda anlatılan ilke nedir?
Hakimlik teminatı</p>
<p>43-Hakim ve savcılar Y&uuml;ksek kurulu başkanı aşağıdakilerden hangisidir?
Adalet bakanı.</p>
<p>44-Hakim ve Savcılar Y&uuml;ksek kurulu &uuml;yeleri-Adalet başkanı ve m&uuml;steşarı
hari&ccedil;-kim tarafından atanır?Ve &uuml;yelerinin g&ouml;rev s&uuml;resi ne kadardır?
Cumhurbaşkanı tarafından 4 yıl s&uuml;reyle.</p>
<p>45-Kanun H&uuml;km&uuml;nde Kararnamelerin Anayasaya uygunluğunu kim yapar? Anayasa
mahkemesi.</p>
<p>46-Anayasa mahkemesi tarafından sadece şekil y&ouml;n&uuml;nden denetlenir? Anayasa
değişikliği.</p>
<p>47-Adliye mahkemelerince verilen karar ve h&uuml;k&uuml;mlerin temyiz mercii
neresidir? Yargıtay.</p>
<p>48-İdari mahkemelerince verilen karar ve h&uuml;k&uuml;mlerin temyiz mercii neresidir?
Danıştay</p>
<p>49-Askeri mahkemelerince verilen karar ve h&uuml;k&uuml;mlerin temyiz mercii
neresidir? Askeri Yargıtay</p>
<p>50-Hakim ve savcılar kim tarafından denetlenirler? Adalet bakanlığı.</p>
<p>51-Anayasa mahkemesi başkanını kim se&ccedil;er? Anayasa mahkemesi &uuml;yeleri.</p>
<p>52-Anayasa mahkemesi &uuml;yelerini kim se&ccedil;er? Cumhurbaşkanı.</p>
<p>53-Anayasa mahkemesi kararlarıyla ilgili birka&ccedil; not yazınız? İptal kararları
geriye y&uuml;r&uuml;mez.<br />
Anayasa mahkemesi kararları kesindir.devletin b&uuml;t&uuml;n kurumlarını ve ger&ccedil;ek/t&uuml;zel
kişileri kapsar.<br />
İptal edilen h&uuml;k&uuml;mler,iptal kararının resmi gazetede yayımlandığı tarihte
y&uuml;r&uuml;rl&uuml;kten kalkar.Anayasa mahkemesi iptal h&uuml;km&uuml;n&uuml;n gireceği tarihi ayrıca
karalaştırabilir.Bu s&uuml;re kararı Resmi gazetede yayımlandığı g&uuml;nden başlayarak 1
(Bir) yılı ge&ccedil;mez.<br />
Anayasa mahkemesi bir h&uuml;km&uuml; iptal ederken kanun koyucu gibi hareket ederek,yeni
bir uygulamaya yol a&ccedil;acak bi&ccedil;imde h&uuml;k&uuml;m tesis edemez.</p>
<p>54-Yargıtay &uuml;yeleri kim tarafından şe&ccedil;ilir? Hakim ve Savcılar Y&uuml;ksek Kurulu.</p>
<p>55-Anayasa ka&ccedil; maddeden oluşmaktadır? 177</p>
<p>56-Anayasamızın ilk maddesini yazınız? T&uuml;rkiye Devleti bir Cumhuriyettir.</p>
<p>57-Vatandaş Kime denir? T&uuml;rkiye&rsquo;ye vatandaşlık bağı ile bağlı olan herkese
vatandaş denir.</p>
<p>58-Bir siyasi partinin kapatılmasına neden olan y&ouml;neticiler ka&ccedil; yıl ceza
alırlar? 5</p>
<p>59-Siyasi partiler hangi mahkemenin kararıyla kapatılırlar? Anayasa
mahkemesi.</p>
<p>60-Se&ccedil;im d&ouml;nemi dolmadan se&ccedil;imlerin yenilenmesine karar verilerek yapılan
se&ccedil;ime ne ad verilir? Erken se&ccedil;im</p>
<p>61-Y&uuml;ksek Se&ccedil;im Kurulunun kararları aleyhine hangi mercie başvurulur? YKS
karaları kesindir.Başvurulamaz&hellip;</p>
<p>62-Bir se&ccedil;im d&ouml;neminde en fazla ka&ccedil; defa ara se&ccedil;ime gidilir?Koşulları
nelerdir.2(iki)kez..Bir ilin veya se&ccedil;im b&ouml;lgesinin TBMM &uuml;yesi kalmaması.</p>
<p>63-Milletvekili tarafından yapılan kanun &ouml;nerisine ne ad verilir? Kanun
teklifi.</p>
<p>64-Bakanlar Kurulu tarafından yapılan kanun &ouml;nerisine ne ad verilir? Kanun
tasarısı.</p>
<p>65-h&uuml;k&uuml;met olmayan,mecliste temsil olunan partilerden en fazla
milletvekiline sahip partiye ne ad verilir? Ana muhalefet partisi.</p>
<p>66-Birden fazla partinin bir araya gelerek h&uuml;k&uuml;met kurmalarına ne ad
verilir? Koalisyon.</p>
<p>67-Salt &ccedil;oğunluk nedir? Meclis &uuml;ye tamsayısının bir fazlası(550/2+1)</p>
<p>68-Milletvekilleri hangi sosyal g&uuml;venlik kurumuna tabidir? T.C Emekli
Sandığı</p>
<p>69-Milletvekiline sağlanan mali imkanların tamamı hangi şıkta verilmiştir?
&Ouml;denek-yolluk-emeklilik imkanı.</p>
<p>70-Hen&uuml;z kanunlaşmamış kanun tasarısının &ouml;mr&uuml; ne kadardır? H&uuml;k&uuml;metin &ouml;mr&uuml;yle
sınırlıdır.</p>
<p>71-Anayasamıza g&ouml;re kanun h&uuml;km&uuml;nde kararname hangi nitelikleri taşımalıdır?
&Ouml;nemli olma,kısa s&uuml;reli olma,Zorunlu olma ve sosyal/eko.haklarla ilgili olma.</p>
<p>72-Anayasamıza g&ouml;re doğrudan iptal davası a&ccedil;abilme hakkı kimlere<br />
aittir? Cumhurbaşkanı,İktidar ve ana muhalefet partisi.</p>
<p>73-T&uuml;z&uuml;kler hakkında kısa notlar yazınız? Kanunların uygulanmasını g&ouml;stermek
veya emrettiği işleri belirtmek, Kanunlara aykırı olamazlar, Danıştay&rsquo;ın
incelemesinden ge&ccedil;erler, Bakanlar kurulunca &ccedil;ıkarılır.</p>
<p>74-Y&ouml;netmelik &ccedil;ıkarma yetkisi sadece kime aittir? Kamu t&uuml;zel kişiliğine
sahip olan kurumlar.</p>
<p>75-Cumhurbaşkanına ilk kez 1982 anayasasıyla hangi değişiklik getirilmiştir?
Başbakanını &ouml;nerisi &uuml;zerine bakanların g&ouml;revine son vermek, Cumhurbaşkanının
dışarıdan se&ccedil;ilmesine olanak sağlanması.</p>
<p>76-Sosyal d&uuml;zen kuralları nelerden oluşmaktadır? Hukuk,gelenek-g&ouml;renek,Din
kuralları,ahlak kuralları,G&ouml;rg&uuml; kuralları.</p>
<p>76-Hukukun diğer sosyal kurallarından temel farkı nedir? Yaptırımı devlet
zoruna dayanması-Kamu g&uuml;c&uuml;n&uuml; barındırması.</p>
<p>77-Bir kuralın hukuk niteliği taşıması i&ccedil;in gerekli olan &uuml;&ccedil; şey nedir?
Yazılı,s&uuml;rekli,genel olması gerekir.</p>
<p>78-Kurallar hiyerarşisinin en &uuml;st sırasındaki norm hangisidir? Anayasa daha
sonra kanun,KHK,t&uuml;z&uuml;k,y&ouml;netmelik.</p>
<p>79-Hangi hukuk dalında &ouml;rf ve adete yer verilmez? Ceza hukuku.</p>
<p>80-B&ouml;lge idare mahkemesi hakkında kısa notlar tutunuz? Adalet bakanlığınca
kurulur.İdare ve vergi mahkemesinin tek hakimle verdiği kararlara karşı yapılan
itirazları kesin olarak karara bağlar.<br />
81-Ceza mahkemeleri genellikle hangi davalara bakmaktadır?
Dolandırıcılık,Hırsızlık,Yaral ama ve Cinayet.</p>
<p>82-Yetkili bir makam tarafından olan ve hala y&uuml;r&uuml;rl&uuml;kte bulunan hukuk
kurallarının t&uuml;m&uuml;ne ne ad verilir? Pozitif Hukuk.</p>
<p>83-Normal erginlik hangi yaşın doldurulmasıyla kazanılır? 18</p>
<p>84-1982 anayasasına g&ouml;re değiştirilemeyecek h&uuml;k&uuml;mler nelerdir? T&uuml;rkiye
Devleti bir Cumhuriyettir.<br />
Atat&uuml;rk milliyet&ccedil;iliğine bağlı,insan haklarına saygılı,Laik,demokratik,soysa hukuk
devletidir. Milli marşı İstiklal Marşıdır. Başkenti Ankara,Dili T&uuml;rk&ccedil;e&rsquo;dir</p>
<p>85-1921 Anayasasının getirdiği en temel yenilik nedir? Milli Egemenlik</p>
<p>86-1982 anayasasında temel hak ve h&uuml;rriyetlerin sınırlandırılmasında dikkate
alır? Milletlerarası hukuktan doğan y&uuml;k&uuml;ml&uuml;l&uuml;klerin ihlal edilmemesi, **&ccedil;&uuml;l&uuml;l&uuml;k
ilkesi,<br />
Demokratik toplum d&uuml;zenin gerekleri, Anayasanın s&ouml;z&uuml;ne ve ruhuna aykırı
olmaması.</p>
<p>87-T&uuml;rk Tarihindeki tek yumuşak anayasamız hangisidir? 1921 Anayasası.</p>
<p>88-Hangileri KHK ile d&uuml;zenleme imkanı yoktur? B&uuml;t&ccedil;e,Temel haklar,Kişi
hakları,Siyasi haklar.</p>
<p>89-Yasama dokunulmazlığının kaldırılması ve &uuml;yeliğin d&uuml;şt&uuml;ğ&uuml;ne dair meclis
kararının iptali Anayasa mahkemesinden ne kadar s&uuml;re i&ccedil;inde istenebilir? Bir
hafta (7 g&uuml;n)</p>
<p>90-Kanun h&uuml;km&uuml;nde kararnameler hangi anayasal d&uuml;zenleme ile gelmiştir? 1961
Anayasasında 1971 değişikliğiyle.</p>
<p>91-T&uuml;rkiye B&uuml;y&uuml;k Millet Meclisi bir yasama yılında en fazla ne kadar tatil
yapar? 3(&Uuml;&ccedil;) ay.</p>
<p>92-Yasama organının bir konuyu araya işlem girmeksizin doğrudan doğruya
d&uuml;zenleyebilmesi hangisi ile ifade edilir? Yasama ilkelliği.</p>
<p>93-Siyasi partilerin mali denetimini ve temelli kapatılmasına kim karar
verir? Anayasa mahkemesi.</p>
<p>94-Anayasa mahkemesini şekil bakımından iptal davası,değişikliğin yayını
tarihinden itibaren ka&ccedil; g&uuml;n i&ccedil;inde alınabilir? 10 (On) g&uuml;n i&ccedil;inde&hellip;</p>
<p>96-Hakimlik teminatının en &ouml;nemli unsuru nedir? Hakimlerin azlolunmaması
ilkesi.</p>
<p>97-Bir mahkemede g&ouml;r&uuml;lmekte olan davanın karara bağlanmasının,karar etkisi
olacak normun anayasaya uygun olup olmamasına bağlı olduğu durumda yapılan denetime
ne ad verilir? Somut norm denetimi</p>
<p>98-Somut norm denetiminde Anayasa mahkemesinin ne kadar s&uuml;re i&ccedil;inde karar
vermesi gerekir? 5 (Beş) ay</p>
<p>99-Halkın doğrudan katılmasını sağlayan y&ouml;nteme ne ad verilir? Referandum.</p>
<p>100-Koruyucu hak ne demektir? Bireyi,devlete ve topluma karşı koruyan hak.</p>
<p>101-1982 Anayasasına g&ouml;re,aşağıdakilerden hangisi TBMM&rsquo;ye karşı,milli
g&uuml;venliğin sağlanmasından sorumludur? Bakanlar Kurulu</p>
<p>102-1982 Anayasasında &ldquo;Siyasi partiler,&ouml;nceden izin almadan kurulurlar&rdquo;h&uuml;km&uuml;
hangi temel ilkenin bir gereğidir? Demokratik devlet</p>
<p>103-1982 Anayasasına g&ouml;re TBMM&rsquo;de aşağıdakilerden hangisinin gizli oyla
yapılması zorunludur? Cumhurbaşkanın se&ccedil;ilmesi.</p>
<p>105-1982 Anayasasına g&ouml;re Cumhurbaşkanının tek başına yapabileceği
işlemlerin yargısal denetimi ile ilgili olarak ne s&ouml;ylenebilir?Bu işlemlere
karşı yargı yoluna gidilemez.</p>
<p>106-Demokratik bir toplumda halk y&ouml;neticilerini nasıl belirler? Se&ccedil;im ile.</p>
<p>107-1982 Anayasasına g&ouml;re,Cumhurbaşkanı tarafından h&uuml;k&uuml;meti kurmakla
g&ouml;revlendirilen kişinin,mutlaka taşıması gereken koşul nedir? Milletvekili
olması(Meclis &uuml;yeliği)</p>
<p>108-1982 Anayasasına g&ouml;re a&ccedil;ık olan bakanlıklarla izinli veya &ouml;z&uuml;rl&uuml;
bakanlara kim vekalet eder? Bakanlardan biri.</p>
<p>109-Dilek&ccedil;e hakkı nedir? Vatandaşların kendileriyle ilgili dilek ve
şikayetleri hakkında yetkili makamlara ve TBMM&rsquo;ye yazı ile başvurma hakkıdır.</p>
<p>110-K&ouml;yde bulunan b&uuml;t&uuml;n se&ccedil;menlerin bulunduğu kurula ne ad verilir? K&ouml;y
derneği.</p>
<p>111-Emlak vergisi veya veraset ve intikal vergisinin aşırı &ouml;l&ccedil;&uuml;de
y&uuml;kseltilmesi,aşağıdaki temel hak ve &ouml;zg&uuml;rl&uuml;klerinden hangisini kısıtlar?
Emlak,arsa,konut taşınmaz mallar olup,M&uuml;lkiyet hakkını kısıtlar.</p>
<p>112-Parlementer sistemin ayrıcı bir &ouml;zelliğini yazınız? Y&uuml;r&uuml;tme organının
yasama organından kaynaklanması ve ona karşı sorumlu olması.</p>
<p>113-1982 Anayasasında yer alan &rdquo;T&uuml;rkiye Devleti &uuml;lkesi ve milletiyle
b&ouml;l&uuml;nmez bir b&uuml;t&uuml;nd&uuml;r &rdquo;h&uuml;km&uuml; hangisinin doğal sonucudur. Milli egemenlik.</p>
<p>114-T&uuml;rk Tarihindeki ilk yazılı anlaşmanın adı nedir? 1876 Kanun-ı Esasi</p>
<p>115-1982 Anayasasına g&ouml;re Cumhuriyetin nitelikleri nelerden oluşur? İnsan
haklarına saygılı,Laik,Demokratik,sosyal hukuk devleti.</p>
<p>116-T&uuml;rk vatandaşlığını kanıtlamada kullanılabilecek belgeler nelerdir?
N&uuml;fus c&uuml;zdanı,N&uuml;fus kayıtları,pasaport,pasavan ve ehliyet.</p>
<p>117-Bir kimsenin kendi şahsına ve malına yapılan ve halen devam eden hukuka
aykırı bir saldırıyı &ouml;nlemek i&ccedil;in yaptığı karşı saldırı niteliğindeki eyleme ne
ad verilir? Meşru m&uuml;dafaa.</p>
<p>118-T&uuml;rkiye&rsquo;nin taraf olduğu Milletler arası s&ouml;zleşme &ccedil;er&ccedil;evesinde hangi
kurumun zorunlu yargı yetkisini kabul etmiştir? Avrupa İnsan Hakları mahkemesi.</p>
<p>119-1982 Anayasasına g&ouml;re savaş,seferberlik,sıkıy&ouml;netim ve olağan&uuml;st&uuml;
hallerde milletlerarası hukuktan doğan y&uuml;k&uuml;ml&uuml;l&uuml;kler ihlal edilmek kaydıyla
aşağıdaki temel hak ve h&uuml;rriyetlerden hangisinin kullanılması durdurulamaz?
Vicdan h&uuml;rriyeti<br />
ali konferansı başladı. Yaklaşık 200 &uuml;lkeden temsilciler, iklim değişikliği ile
m&uuml;cadele yollarını g&ouml;r&uuml;şmek &uuml;zere Endonezya&rsquo;nın Bali kentinde biraraya geldi.<br />
Birleşmiş Milletler&rsquo;in &ouml;nc&uuml;l&uuml;ğ&uuml;nde bug&uuml;n başlayan iki haftalık toplantıda,
ge&ccedil;erlik s&uuml;resi 2012 yılında dolacak olan Kyoto Protokol&uuml;&rsquo;n&uuml;n yerini alacak
yeni bir anlaşma i&ccedil;in m&uuml;zakere &ccedil;er&ccedil;evesi ve takvmi belirlenmesi &ouml;ng&ouml;r&uuml;l&uuml;yor.</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal"><strong><span style="text-decoration: underline;">Adli Terimler:</span></strong></p>
<p class="MsoNormal">&nbsp;</p>
<p>Adli sicil kaydı: Kesinleşmiş mahkumiyet kararlarını g&ouml;sterir kayıt.<br />
Aleniyet: A&ccedil;ıklık, izlenebilirlik.</p>
<p>Ara karar: Son h&uuml;k&uuml;m olmayıp h&uuml;kme giden yolda verilen ara, yardımcı
kararlar.</p>
<p>Arama (Adli arama): H&acirc;kim kararı ile yapılan ev ve işyeri araması.</p>
<p>Arama (&Ouml;nleme araması): Su&ccedil;un işlenmeden &ouml;nceki aşamasında idarece<br />
y&uuml;r&uuml;t&uuml;len arama bi&ccedil;imi.</p>
<p>Ayırma (Davaların ayrılması): Fiili ya da hukuki bağlantısı olmayan veya
birisi<br />
hakkında verilecek kararın diğer davayı etkilemeyeceği durumlarda<br />
davaların ayrılarak y&uuml;r&uuml;t&uuml;lmesi.</p>
<p>Bağlantı (Davalar arası): İrtibat, bir dava hakkında verilecek karar
diğerini<br />
etkileyebilecek durumda olması.</p>
<p>Beraat: Su&ccedil;lu bulunmama hali, başlangı&ccedil;tan beri kirlenmemiş olma.<br />
Bihakkın (Tahliye): Şart olmaksızın, hakkıyla cezasını &ccedil;ekmiş, t&uuml;ketmiş olma.</p>
<p>Bilirkişi (Ehl-i vukuf): Alanında g&ouml;r&uuml;ş&uuml;ne başvurulacak kadar uzman.</p>
<p>Birleştirme (Davaların birleştirilmesi): Aralarında bağlantı olan, biri
hakkında<br />
verilecek kararın diğer dava sonucu etkileyecek olması durumunda<br />
her iki davanın birlikte y&uuml;r&uuml;t&uuml;lmesi.</p>
<p>Bono: T&uuml;rk Ticaret Kanunu&rsquo;nda d&uuml;zenlenen, alacağın miktarını, bor&ccedil;lusunu ve<br />
&ouml;denme zamanını g&ouml;steren belge.</p>
<p>Butlan: Hukuki işlemin hi&ccedil; doğmamış sayılması, yok sayılması.<br />
Cebri icra: Zorla yerine getirme.</p>
<p>Celse: Oturum, duruşma.</p>
<p>Ceza fişi: Kesinleşen kararların t&uuml;r&uuml; ve miktarına ilişkin adli sicil
(sabıka)<br />
kayıtlarına işlemek &uuml;zere d&uuml;zenlenen ve adli sicile sevkedilen evrak.</p>
<p>Ciranta: Bir senedi ciro eden kimse.</p>
<p>Ciro: Bir senet veya havalenin alacaklı tarafından diğeri namına &ccedil;evrilmesi
ile<br />
&uuml;zerine buna dair şerh verilmesi.</p>
<p>&Ccedil;ağrı k&acirc;ğıdı: Cumhuriyet Savcılığı aşamasında dinenmesi gereken ş&uuml;pheli,<br />
mağdur ve tanıkların gelmesini isteyen kağıt.</p>
<p>Daimi arama: Faili bulunamayan su&ccedil;ların araştırıldıkları dosyalara verilen
isim.</p>
<p>Davaname: Cumuriyet savcısının konuyu ilgilendiren ancak ceza davası
niteliği<br />
taşımadığı i&ccedil;in hukuk mahkemelerinde g&ouml;r&uuml;lecek olan davayı a&ccedil;tığı<br />
belge.</p>
<p>A&ccedil;ıklama: &Ouml;zellikle mahkemeler, genel olarak da adliyelerin g&uuml;nl&uuml;k<br />
işleyişinde sıkca kullanılan hukuki terimlerden bir kısmı kitabın daha kolay<br />
anlaşılması amacıyla listelenerek kısaca a&ccedil;ıklanmaya &ccedil;alışılmıştır. Terimlerin<br />
a&ccedil;ıklamaları T&uuml;rk Dil Kurumu g&uuml;ncel t&uuml;rk&ccedil;e s&ouml;zl&uuml;k ve &ccedil;eşitli hukuk<br />
s&ouml;zl&uuml;klerinden yararlanılarak hazırlanmıştır.</p>
<p>Davanın kabul&uuml;: Dava dilek&ccedil;esindeki istemi b&uuml;t&uuml;n&uuml; ile veya kısmen kabul eden<br />
hukuk mahkemesi sonu&ccedil; kararları.</p>
<p>Davanın reddi: Dava dilek&ccedil;esindeki istemi b&uuml;t&uuml;n&uuml; ile veya kısmen reddeden<br />
hukuk mahkemesi sonu&ccedil; kararları.</p>
<p>Davetiye: Duruşmaya &ccedil;ağrı kağıdı.</p>
<p>Davetname: &Ccedil;ağırmaya yetkili makamların kişinin hazır olması bakımından<br />
&ccedil;ıkarılan &ccedil;ağrı kağıdı.</p>
<p>Delil: Bir vakıanın varlığını ortaya koyan vasıta, işaret.</p>
<p>Denetimli serbestlik: Cezaevine girmeksizin, dışarıda bazı kurallara uyma<br />
zorunluluğu.</p>
<p>Disiplin hapsi: Yargılama s&uuml;recinde d&uuml;zen bozuculara karşı , temyizi ve
itirazı<br />
kabil olmayan, şartla tahliyesi bulunmayan 4 g&uuml;n&uuml; ge&ccedil;meyen<br />
uslandırma ama&ccedil;lı bir hapis t&uuml;r&uuml;.</p>
<p>D&uuml;plik: Davanın replik (cevaba cevap) yazısına karşı davalının vermiş olduğu<br />
cevap; ikinci cevap.</p>
<p>D&uuml;şme kararı: Y&uuml;r&uuml;me şartını kaybeden davaların g&ouml;r&uuml;lemeyeceğine ve s&uuml;kutuna<br />
ilişkin karar.</p>
<p>El koyma: Su&ccedil;a konu veya delil niteliği olan eşya ve malın Cumhuriyet
Savcılığı<br />
ve mahkeme aşamasında alıkonulması.</p>
<p>Emanet: Alıkonulan eşya,mal veya paranın yargı kararı kesinleşinceye kadar<br />
adliyede, Cumhuriyet Savcılığı b&uuml;nyesinde bir deftere konularak<br />
muhafazası.</p>
<p>Emanet memuru: Emanet eşya işleri ile uğraşan memur.</p>
<p>Fail: Hareketi ger&ccedil;ekleştiren kişi (&ouml;zne), su&ccedil;u işleyen.</p>
<p>Faili me&ccedil;hul: Kim tarafından işlendiği bilinmeyen hadiseler.</p>
<p>Fezleke: H&uuml;lasa netice yazısı (soruşturma evrakının &ouml;zeti), &ouml;zel anlamıyla
ağır ceza<br />
mahkemesinin bulunmadığı il&ccedil;elerde meydana gelen olayların, ağır<br />
ceza mahkemesi g&ouml;rev alanına girdiğinde, b&uuml;t&uuml;n deliler toplanarak<br />
merkez Cumhuriyet Başsavcılıklarına g&ouml;nderilen iddianame &ouml;ncesi<br />
sonu&ccedil; yazısı.</p>
<p>Gaip: Yokluğu farzedilen kişi, bulunduğu yer bilinmeyen, yurt dışında olup
da<br />
getirilemeyen veya getirilmesi uygun olmayan kişi.</p>
<p>Gerek&ccedil;eli karar: Duruşma bitiminde verilen son kısa h&uuml;km&uuml;n gerektirici<br />
sebeplerini i&ccedil;eren mahkeme kararı.</p>
<p>G&ouml;rev: Kanunla tespit edilen ve bir mahkemenin yargılama alanını g&ouml;steren<br />
terim.</p>
<p>G&ouml;zaltı: Ortaya &ccedil;ıktığı d&uuml;ş&uuml;n&uuml;len bir su&ccedil;un araştırılması, delillerin
karartılmasının<br />
engellenmesi ve kişinin sorgusu i&ccedil;in ş&uuml;phelinin savcı talimatı ile;<br />
kanunda belirtilen s&uuml;rece alıkonulması.</p>
<p>Haciz: Alacaklının talebi ve yasal koşulların oluşması halinde bor&ccedil;lunun
malları<br />
&uuml;zerine satılamaz şerhinin konulması ve gerekirse malın yed-i<br />
emine teslimini g&ouml;steren hukuki tanım.</p>
<p>Hak d&uuml;ş&uuml;r&uuml;c&uuml; s&uuml;re: Var olan bir hakkın kullanılmaması halinde belirli bir
s&uuml;re<br />
sonunda bu kullanım hakkını d&uuml;ş&uuml;ren s&uuml;re.</p>
<p>Hak ehliyeti: Hukuki işlem yapabilme ehliyeti, alacak sahibi olma, bor&ccedil;lanabilme<br />
yeteneği.</p>
<p>H&acirc;kimin reddi: Yasada yazılı nedenlerle davaya bakması adaletin yerine<br />
getirilmesini engelleyeceği d&uuml;ş&uuml;n&uuml;len h&acirc;kimin davaya bakmamasını<br />
talep etme.</p>
<p>Hakkın k&ouml;t&uuml;ye kullanılması: Hukukun korumadığı hak kullanma bi&ccedil;imi.</p>
<p>Haksız fiil: Hukukun korumadığı, hakka dayanmayan fiil.</p>
<p>Hapsen tazyik: Hapisle zorlama, hukuka aykırı hareket edeni uslandırma,<br />
hukuka uymaya zorlama hapsi.</p>
<p>Har&ccedil;: Resmi bir muamele başvurusu yapılırken &ouml;denmesi gereken yasal meblağ.</p>
<p>Har&ccedil; tahsil m&uuml;zekkeresi: Kesinleşen kararlara ilişkin har&ccedil;ların tahsili i&ccedil;in<br />
maliyeye yazılan yazı kağıdına verilen ad.</p>
<p>Heyet: &Uuml;&ccedil; veya daha fazla h&acirc;kimin bir arada &ccedil;alışması.</p>
<p>Hukuki ihtilaf: İ&ccedil;erisinde su&ccedil; barındırmayan, ceza soruşturmasına konu
olmayan<br />
&ccedil;ekişme.</p>
<p>Hukuki işlem: Yasadan kaynaklanan ve hukuk alanında sonu&ccedil; doğuran işlemler.</p>
<p>H&uuml;kmen tutuklu (H&uuml;k&uuml;m&ouml;zl&uuml;): Hakkında ilk derece mahkemesinin mahkumiyet<br />
kararı verdiği ve tutuk halinin devamına h&uuml;kmettiği kişinin hukuki<br />
durumu.</p>
<p>H&uuml;km&uuml;n a&ccedil;ıklanmasının geri bırakılması: Sanık hakkında 2 yıl ve daha az<br />
mahkumiyet s&ouml;zkonusu olduğunda ve yasal şartlar &ccedil;er&ccedil;evesinde;<br />
verilen kararı a&ccedil;ıklamadan sonu&ccedil; doğurmayacak bir alana terk etme.</p>
<p>H&uuml;k&uuml;m fıkrası: Son kararın yer aldığı duruşma sonu yazılan b&ouml;l&uuml;m.<br />
İcra: Kanunen y&uuml;k&uuml;ml&uuml; olan taraf&ccedil;a yerine getirmesi gereken bir edimin veya<br />
hareketin yerine getirilmemesi halinde; devlet g&uuml;c&uuml; ile yerine<br />
getirilmesi.</p>
<p>İddianame: Ş&uuml;pheli hakkında mahkemeye sunulan ve cezaladırma talebini i&ccedil;eren<br />
Cumhuriyet Savcılığı yazısı.</p>
<p>İflas: Bor&ccedil;ların &ouml;denememesi hali.</p>
<p>İhzar (Zorla getirme): Kolluk g&uuml;c&uuml; ile mahkemeye zorla getirme.</p>
<p>İlam: Kesinleşmiş ve yerine getirilmesi gereken mahkeme kararı.</p>
<p>İncelenmeksizin ret: Esas incelemeye konu olamayacak başvurunun usuli yoldan<br />
reddi.</p>
<p>İnfazın ertelenmesi: Belirli mahkumiyetlerin infazının, ge&ccedil;erli mazeret ve<br />
koşulların varlığı halinde ileriye tehiri.</p>
<p>İptal: Hukuki işlemin ge&ccedil;ersizliğinin tespiti.</p>
<p>İsticvap: Bir tarafın kendi aleyhine olan belli bir (veya birka&ccedil;) vakıa
hakkında<br />
mahkeme tarafından sorguya &ccedil;ekilmesi.</p>
<p>İstinabe: Mahkeme mahallinde bulunmayan ve mahkemece dinlenmesi<br />
gereken kişinin, yargılayan mahkemenin talebi ile oturduğu yer<br />
mahkemesince dinlenmesi.</p>
<p>İştirak: Bir fiile birden &ccedil;ok kişinin katılımı.</p>
<p>İtiraz: Yapılan bir hukuki işleme veyahut verilen bir karara karşı; kanunun<br />
g&ouml;sterdiği şekilde ikinci bir kez inceleme istemi.</p>
<p>İzalei ş&uuml;yu (Ortaklığın giderilmesi): İştirak halindeki m&uuml;lkiyetin
paylaştırıması<br />
işlemi.</p>
<p>Kalem: Mahkemeler ve Cumhuriyet savcılıklarının yazı işlerini y&uuml;r&uuml;ten
birimi.</p>
<p>Kambiyo senedi: Yasaca ayrıcalıklı korunan senet t&uuml;r&uuml;.</p>
<p>Kamu d&uuml;zeni: Yasaların &ouml;ng&ouml;rd&uuml;ğ&uuml; ve toplumun genelini ilgilendiren uyum
hali.</p>
<p>Kamu yararı: Toplumun geneline ve d&uuml;zene yansıyan yarar.</p>
<p>Kanun yararına temyiz (Yazılı emir): Hukuka aykırı bir sonu&ccedil; doğuran ancak<br />
Yargıtay incelemesinden ge&ccedil;meksizin kesinleşen h&uuml;k&uuml;mlerle ilgili<br />
olarak Adalet Bakanlığı ile Cumhuriyet Başsavcılığı tarafından<br />
başvurulan bir kanun yoludur, amacı ise yanlış hukuki kararların<br />
yerleşmesini ve &ouml;rnek alınmasını engellemektir.</p>
<p>Karar d&uuml;zeltme: Yargıtay ilgili dairesinin bozma veya onama kararından
sonra;<br />
a&ccedil;ık bir hukuka aykırılık g&ouml;r&uuml;ld&uuml;ğ&uuml;nde son kez aynı daireden</p>
<p>kararını tekrar g&ouml;zden ge&ccedil;irmesine ilişkin istemin kabul&uuml;.</p>
<p>Kararın tavzihi / a&ccedil;ıklanması: Verilen kararda belirsiz hususların kararı
veren<br />
merci tarafından a&ccedil;ıklığa kavuşturulması.</p>
<p>Katılan (M&uuml;dahil): Davada taraf olan ve yasanın dava taraflarına verdiği
hakları<br />
kullanan kişi.</p>
<p>Kayıt tashihi / d&uuml;zeltmesi: Herhangi bir resmi kayıttaki yanlışlığın mahkeme<br />
yoluyla d&uuml;zeltilmesi.</p>
<p>Kesinleş(tir)me: Hukuki yolları t&uuml;keten bir yargı kararının sonu&ccedil; doğurması
i&ccedil;in<br />
mahkemece d&uuml;ş&uuml;len şerh.</p>
<p>Kısa karar: Duruşma sonrası verilen ve hen&uuml;z gerek&ccedil;esi yazılmayan karar.</p>
<p>Kolluk: G&uuml;venlik birimleri.</p>
<p>Komisyon (Adli Yargı Adalet Komisyonu): Ağır ceza mahkemesi bulunan<br />
yerlerde teşkilatlanan, başkanı Hakimler ve Savcılar Y&uuml;ksek Kurulu<br />
(HSYK)nca atanan, bir &uuml;yesi Başsavcı, diğer &uuml;yesi ise yine HSYK&rsquo;ca<br />
belirlenen, personel işlerini y&uuml;r&uuml;ten kurul.</p>
<p>Konkordato: D&uuml;r&uuml;st bor&ccedil;lunun &ouml;nerip de en az &uuml;&ccedil;te iki alacaklısının kabul&uuml;<br />
ve ticaret mahkemesinin onaması ile ortaya &ccedil;ıkan bir anlaşmayla,<br />
alacaklıların bir kısım alacaklarından vazge&ccedil;mesi ve bor&ccedil;lunun da bu anlaşmaya
g&ouml;re kabul edilen borcun belli y&uuml;zdesini, tamamını ya da daha fazlasını, kabul
edilen vadede &ouml;deyerek borcundan<br />
kurtulması.</p>
<p>Kovuşturma: Ceza davasının mahkeme evresi; yargılama safhası.</p>
<p>Layiha: Herhangi bir konuda bir g&ouml;r&uuml;ş ve d&uuml;ş&uuml;nceyi bildiren yazı; tasarı.</p>
<p>Maddi hata: Esasa ilişkin olmayan, yazıda ve rakamda yanılgıyı g&ouml;sterir
hata.</p>
<p>Mahcuz (Hacizli): &Uuml;zerinde satılamaz şerhi bulunan menkul / gayrımenkul her<br />
t&uuml;rl&uuml; eşya veya değer.</p>
<p>Mahkum (H&uuml;k&uuml;ml&uuml;): Mahkumiyet kararı kesinleşen sanık.</p>
<p>Mahsup: Daha &ouml;nce tutuklu kalıp beraat eden kişinin bir sonraki eylemi
sonucu<br />
aldığı mahkumiyetten &ouml;nceki tutukluluk s&uuml;resinin d&uuml;ş&uuml;lmesi; hesap<br />
etmek, hesaba ge&ccedil;irmek.</p>
<p>Malen sorumlu(luk): Cezai y&ouml;nden değil malvarlığı ile sorumlu(luk).</p>
<p>Men&rsquo;i m&uuml;dahale: Bir gayrımenkulun haksız işgali halinde a&ccedil;ılan dava ve
sonu&ccedil;ta<br />
verilen karar.</p>
<p>Mevcutlu: Kolluk tarafından bir soruşturma evrakı getirilirken, soruşturmaya<br />
konu şahısların da birlikte getirilmesi.</p>
<p>M&uuml;dafi: Savunman, vekalet ilişkisi olmaksızın yasa gereği ş&uuml;pheli ve sanığı<br />
savunan avukata verilen yasal isim.</p>
<p>M&uuml;ddeabih: Hukuk davasının konusu, talep edilen şey.</p>
<p>M&uuml;ddetname: H&uuml;k&uuml;ml&uuml;n&uuml;n cezasını form&uuml;le eden Cezaevine girilmesi ve<br />
&ccedil;ıkılması gereken zamanla beraber, yasal ceza indirimlerini de konu<br />
eden savcılık k&acirc;ğıdı.</p>
<p>M&uuml;sadere: Kendiliğinden su&ccedil; teşkil eden veya su&ccedil;ta kullanılan eşyanın
zoralımı.</p>
<p>M&uuml;şterek: Pay &uuml;zerinde tasarruf edilebilen ortaklık hali.</p>
<p>M&uuml;talaa: G&ouml;r&uuml;ş.</p>
<p>M&uuml;temmim c&uuml;z: B&uuml;t&uuml;n&uuml;n vazge&ccedil;ilmez par&ccedil;ası.</p>
<p>M&uuml;teselsil: Birbirini izleyen, zincirleme.</p>
<p>M&uuml;vekkil: Vekalet veren, avukatın vekilliğini yaptığı kişi.</p>
<p>M&uuml;zakere: Karşılıklı konuşma, tartışma.</p>
<p>M&uuml;zekkere: İstem yazısı.</p>
<p>N&uuml;fus tashihi: Ad, soyad ve yaş d&uuml;zeltme işlemlerinin genel adı.</p>
<p>Replik: Davacının, davalının cevap layihasına (yazısına) karşı verdiği
cevap;<br />
cevaba cevap.</p>
<p>Resen: Kendiliğinden.</p>
<p>Resim ve har&ccedil;: Vergi isimleri.</p>
<p>Sanık: Hakkında kamu davası a&ccedil;ılan ş&uuml;pheli.</p>
<p>Savunma: Ş&uuml;pheli veya sanığın &uuml;zerine atılı su&ccedil; isnadına karşı, aleyhindeki<br />
delilleri bertaraf etmek &uuml;zere kendisi ile fiil arasındaki ilişkiyi,<br />
kendi g&ouml;r&uuml;ş&uuml;yle ortaya koymak, kendi g&ouml;r&uuml;ş&uuml;ne ilişkin olarak delil<br />
toplanmasını talep etmek.</p>
<p>Sorgu: Ş&uuml;pheli veya sanığın h&acirc;kimce ifadesinin alınması ve soru sorulması.</p>
<p>Soruşturma: Savcılığın iddianamenin kabul&uuml; aşamasına kadar su&ccedil; ve ş&uuml;pheli<br />
hakkında yaptığı incelemeler.</p>
<p>Soruşturma izni: Haklarında belirli durumlarda soruşturma amirin iznine tabi<br />
kişiler hakkında verilen izin.</p>
<p>Su&ccedil; eşyası: Su&ccedil;ta kullanılan veya kendiliğinden bulundurulması su&ccedil; olan
eşya.</p>
<p>Su&ccedil;tan zarar g&ouml;ren: Mağdur.</p>
<p>S&uuml;but: Su&ccedil;un delillendirilmesi, ispat hali.</p>
<p>S&uuml;re: Hukuki işlemlerin ortaya konması gereken zaman..</p>
<p>Şartla salıverme: Cezasının bir kısmını &ccedil;eken h&uuml;k&uuml;ml&uuml;n&uuml;n iyi hali
g&ouml;zetilerek,<br />
geri kalan kısmını dışarıda ge&ccedil;irmesi ve bu s&uuml;rede tekrar su&ccedil;<br />
işlememesi şartını i&ccedil;eren durumdur.</p>
<p>Şik&acirc;yet&ccedil;i (M&uuml;şteki): Şik&acirc;yet eden, şik&acirc;yete hakkı olan.</p>
<p>Ş&uuml;pheli: Soruşturmaya konu olan kişi.</p>
<p>Tahliye: Haksız yere bir taşınmazı işgal eden kişinin devlet g&uuml;c&uuml; ile
taşınmadan<br />
&ccedil;ıkarılması; h&uuml;k&uuml;ml&uuml; ve tutuklunun cezaevinden &ccedil;ıkarılması.</p>
<p>Talep: İstem, isteme.</p>
<p>Talimat: Bir yer Savcılığı veya mahkemesinin diğer yer savcılık veya<br />
mahkemesinden soruşturma veya dava i&ccedil;in bir işlem yapması<br />
istemi.</p>
<p>Tanık: Soruşturma veya dava konusu ile ilgili bilgisi olan ve dinlenmesine
karar<br />
verilen kişi.</p>
<p>Tebell&uuml;ğ: Bir bildiriyi imza karşılığı alma.</p>
<p>Tebliğ: Bir kararı muhatabına resmi olarak iletme.</p>
<p>Tedbir: Hen&uuml;z kararı verilmeyen konularda ,dava sonuna kadar belirli
&ouml;nlemlerin<br />
alınması.</p>
<p>Tekemm&uuml;l: Tamamlama.</p>
<p>Tekit: &Uuml;steleme.</p>
<p>Temerr&uuml;t: Gecikme.</p>
<p>Temlik (Temell&uuml;k): Devretme, devralma.</p>
<p>Temyiz: &Uuml;st mahkeme incelemesi talebi.</p>
<p>Tenkis: Azaltma.</p>
<p>Tensip: Uygun g&ouml;rme.</p>
<p>Terak&uuml;m: Birikme, yığılma.</p>
<p>Tereke (Bırakıt): &Ouml;lenin aktif malvarlığı.</p>
<p>Teşmil: Yayma.</p>
<p>Tevzii (b&uuml;rosu): Dağıtma (Gelen evrak ve davayı ilgili birimlere dağıtan
b&uuml;ro).</p>
<p>Tutuklama: Tedbir, soruşturma veya davanın daha selim y&uuml;r&uuml;mesi i&ccedil;in
h&uuml;rriyetin<br />
kısıtlanmasına ilişkin karar.</p>
<p>Tutuklu: Tutuklanan ş&uuml;pheli veya sanık.</p>
<p>&Uuml;cret-i vekalet: Avukatlık &uuml;creti.</p>
<p>UYAP (Ulusal Yargı Ağı Projesi): B&uuml;t&uuml;n adli işlemlerin elektronik ortamda<br />
yapılarak muhafazasını sağlayan proje; bu projenin ardından ulusal<br />
yarğı ağına verilen kısa isim.</p>
<p>Uzlaşma: Belirli bi edim karşılığı olarak veya olmayarak ş&uuml;pheli ve mağdur<br />
tarafın anlaşıp uzlaşması sonucu dava a&ccedil;ılmaması veya d&uuml;şmesi.</p>
<p>Vareste (Bağışık): Mahkeme kararı ile duruşmaya katılmama izni.</p>
<p>Vasıf: Su&ccedil;un hangi kanun maddesini ihlal ettiğine ilişkin olan hukuki tabir;<br />
nitelik.</p>
<p>Vasi: Vesayet atındakinin hukuki işlemlerini yapan, mahkeme kararı ile
atanan<br />
kişi.</p>
<p>Vekil: Vekalete dayalı iş yapan.</p>
<p>Velayet (veli): Reşit olmayan &ccedil;ocuğun kanuni temsilcisi, kanuna g&ouml;re anne ve<br />
baba.</p>
<p>Veraset (ilamı): Miras&ccedil;ıları g&ouml;steren belge.</p>
<p>Vesayet: Vasi ile temsil edilme hali.</p>
<p>Yakalama emri: &Ccedil;ağrıldığı halde mahkemeye gelmeyen kişinin yakalanması i&ccedil;in<br />
&ccedil;ıkarılan karar.</p>
<p>Yargılama gideri: Soruşturma ve mahkeme aşamasında yapılan masraflar.</p>
<p>Yargılamanın yenilenmesi: Kesinleşen bir yargı kararının, belirli şartların<br />
varlığında tekrar g&ouml;r&uuml;lmesi.</p>
<p>Yaş tashihi: N&uuml;fusa yanlış yazılan yaşın mahkemece d&uuml;zeltilmesi.</p>
<p>Yazı işleri: Mahkemenin yazı işlerini y&uuml;r&uuml;ten birim.</p>
<p>Yediemin: Birden &ccedil;ok kişi arasında hukuki durumu &ccedil;ekişmeli olan bir malın,<br />
&ccedil;ekişme sonu&ccedil;lanıncaya kadar emanet olarak bırakıldığı kimse,<br />
g&uuml;venilir kişi.</p>
<p>Yemin: Tanıkların veya tarafların doğru s&ouml;ylediğine ilişkin bağlayıcı metni<br />
tekrarlamaları.</p>
<p>Yetki: Yasal olarak bir merciin bakabileceği işler.</p>
<p>Yokluk (Keenlemyek&uuml;n): Hukuken işlemin sonu&ccedil; doğurmaması.</p>
<p>Y&uuml;r&uuml;tmeyi durdurma: Hukuki işlemin y&uuml;r&uuml;mesinin engellenmesi.</p>
<p>Zabıt: Bir hukuki durumu tespit eden yazılı kağıt.</p>
<p>Zamanaşımı: Kanunda &ouml;ng&ouml;r&uuml;len ve belirli koşullar altında ge&ccedil;mekle, bir
hakkın<br />
kazanılmasını, kaybedilmesini veya bir y&uuml;k&uuml;ml&uuml;l&uuml;kten kurtulmayı<br />
sağlayan s&uuml;re.</p>
<p>Zımni (Kabul, ret): &Uuml;st&uuml; kapalı, a&ccedil;ık olmayan; ima yoluyla.<br />
Zilyet(lik): Sahibi kendisi olsun olmasın bir malı kullanmakta olan, elinde
tutan<br />
kimse.&nbsp;</p>
<p><strong><span style="text-decoration: underline;">CUMHURİYET SAVCISININ G&Ouml;REVLERİ:</span></strong><br />
1- Adli g&ouml;reve ilişkin işlem yapmak, duruşmalara katılmak ve kanun yollarına
başvurmak<br />
2-Cumhuriyet Başsavcısının verdiği idari ve adli g&ouml;revleri yerine getirmek<br />
3-Gerektiğinde Cumhuriyet Bassavcısına vekalet etmek<br />
4-Kanunlarla verilen diğer g&ouml;revleri yerine getirmek</p>
<p >
<strong><span style="text-decoration: underline;">CUMHURİYET BAŞSAVCISININ G&Ouml;REVLERİ</span></strong><br />
1-Cumhuriyet Başsavcılığını temsil etmek<br />
2-Başsavcılığın verimli,uyumlu ve d&uuml;zenli &ccedil;alışmasını sağlamak, işb&ouml;l&uuml;m&uuml; yapmak<br />
3-Gerektiğinde adli g&ouml;reve ilişkin işlem yapmak , duruşmalara katılmak ve kanun
yollarına başvurmak<br />
4-Kanunlarla verilen diğer g&ouml;revleri yerine getirmek</p>
<p >
<strong><span style="text-decoration: underline;">BAŞSAVCILIĞIN G&Ouml;REVLERİ</span></strong><br />
1-Kamu davası a&ccedil;ılmasına yer olup olmadığına dair soruşturma yapmak veya
yaptırmak<br />
2-Kanun h&uuml;k&uuml;mlerince yargılama faaliyetlerini kamu adına izlemek,bunlara
katılmak gerektiğinde kanun yollarına başvurmak<br />
3-Mahkemelerce kesinleşen h&uuml;k&uuml;mlerin ger&ccedil;ekleşmesi i&ccedil;in işlem yapmak ve izlemek<br />
4-Kanunlarla verilen diğer g&ouml;revleri yerine getirmek</p>
<p >
<strong><span style="text-decoration: underline;">HAKİMLER VE SAVCILAR Y&Uuml;KSEK KURULU</span></strong><br />
*Adli ve idari hakim ve savcıları g&ouml;reve kabul etme,nakletme,atama,disiplin ve
terfi işlemlerini yapar<br />
*Kurumun başkanı Adalet Bakanıdır.Adalet Bakanı M&uuml;steşarı kurumun tabii
&uuml;yesidir.<br />
*HSYK ayrı bir t&uuml;zel kişiliğe sahip değildir.<br />
*Cumhur Başkanı,3 asil 3 yedek Yargıtaydan,2 asil 2 yedek Danıştaydan se&ccedil;er.<br />
*&Uuml;yeleri d&ouml;rt yıl i&ccedil;in se&ccedil;ilir<br />
*HSYK, Danıştay &uuml;yelerinin d&ouml;rtte &uuml;&ccedil;&uuml;n&uuml;, Yargıtay &uuml;yelerinin tamamını se&ccedil;er.<br />
*HSYK&rsquo;nın kararları yargı denetiminin dışındadır.<br />
Yazı işleri ilgisine g&ouml;re Cumhuriyet Başsavcısı , mahkeme başkanı ve hakimlerin
denetiminde, yazı işleri m&uuml;d&uuml;r&uuml;n&uuml;n y&ouml;netiminde zabıt katibi, memur ve
m&uuml;başirler tarafından y&uuml;r&uuml;t&uuml;l&uuml;r. İlgisine g&ouml;re Cumhuriyet Başsavcısı Cumhuriyet
Savcısına , Mahkeme başkanı da &uuml;yelere yazı işlerinin y&uuml;r&uuml;t&uuml;lmesinin
denetlenmesinde g&ouml;rev verebilir. Yazı işleri m&uuml;d&uuml;r&uuml; ilgisine g&ouml;re C.
Başsavcısı, Mahkeme Başkanı ve hakimlerin onayını alrak y&ouml;netimindeki zabıt
katipleri arasında işb&ouml;l&uuml;m&uuml; yapabilir. yazı işlerinin gecikmesinde kalemden
sorumlu zabıt katibi ve yazı işleri m&uuml;d&uuml;r sorumludur.</p>
<p><strong><span style="text-decoration: underline;">Y&Uuml;KSEK MAHKEMELER</span></strong><br />
<strong>1-ANAYASA MAHKEMESİ:</strong><br />
*11 asil d&ouml;rt yedek &uuml;yeden oluşur.<br />
* &uuml;yelerini Cumhurbaşkanı se&ccedil;er.<br />
*Başkanını kendi &uuml;yeleri arasından salt &ccedil;oğunlukla se&ccedil;er<br />
*Başkan ve vekili d&ouml;rt yıl i&ccedil;in se&ccedil;ilir.<br />
<strong>G&Ouml;REVLERİ</strong><br />
-Milletvekili dokunulmazlıklarının kaldırılmasıyla ilgili itirazlara bakar.<br />
-Kanunların,KHK (kanun h&uuml;km&uuml;ndeki kararnamelerin), ve Anayasa değişikliklerinin
uygunluk denetimini yapar.<br />
-Anayasa değişikliklerini sadece şekil y&ouml;n&uuml;nden denetler.<br />
-Meclis i&ccedil; t&uuml;z&uuml;ğ&uuml;n&uuml; ile ilgili itirazlara bakar.<br />
-Siyasi partilerin mali denetimini yapar.<br />
-Siyasi partilerin kapatılma davasına bakar.<br />
-Uyuşmazlık Mhakemesinin başkanını se&ccedil;er<br />
-Cumhurbaşkanı,Yargıtay Cumhuriyet Başsavcısı ve vekilini, Hakimler ve Savcılar
y&uuml;ksek kurulu başkan ve &uuml;yelerini,Sayıştay başkan ve &uuml;yelerini g&ouml;revleri ile
ilgili su&ccedil;lardan dolayı Y&Uuml;CE DİVAN sıfatıyla yargılar<br />
Meclis başkanı ve millet vekilleri y&uuml;ce divanda yargılanamaz.<br />
2-<strong>YARGITAY</strong>:Adliye Mahkemelerince
verilen karar ve h&uuml;k&uuml;mlerin son inceleme mercii olup ayrıca belli davalara da
ilk ve son derece mahkemsi olark bakar, Yargıtay &uuml;yeleri, hakimler ve Savcılar
Y&uuml;ksek Kurulu &uuml;yelerince se&ccedil;ilir.<br />
3-<strong>DANIŞTAY</strong>:İdare ve Vergi
mahkemelerince verlien karar ve h&uuml;k&uuml;mlerin son inceleme mercii olup ayrıca
belli davalara ilk ve son derece mahkemesi olarak bakar. &Uuml;yelerinin d&ouml;rtte &uuml;&ccedil;&uuml;
HSYK , d&ouml;rtte biri Cumhurbaşkanı tarafından se&ccedil;ilir.<br />
4-<strong>ASKERİ YARGITAY</strong>:Askeri
mahkemelerce verilen karar ve h&uuml;k&uuml;mlerin son inceleme merciidir. &Uuml;yeleri
Cumhurbaşkanı tarafından se&ccedil;ilir.<br />
5-<strong>ASKERİ Y&Uuml;KSEK İDARE MAHKEMESİ:</strong>
Asker kişileri ilgilendiren ve askeri hizmete ilişkin idari işlemlerden doğan
uyuşmazlıkların yargı denetimini yapar.<br />
6-<strong>UYUŞMAZLIK MAHKEMESİ:</strong> Adli, idari
ve askeri yargı mercileri arasındaki g&ouml;rev ve h&uuml;k&uuml;m uyuşmazlıklarını kesin
olarak &ccedil;&ouml;z&uuml;mlemeye yetkilidir. Bu mahkemenin başkanlığını Anayasa Mahkemesinin
kendi &uuml;yeleri i&ccedil;inden g&ouml;revlendirdiği &uuml;ye yapar.<br />
NOT: SAYIŞTAY VE HAKİMLER VE SAVCILAR Y&Uuml;KSEK KURULU 1982 ANAYASASINDA
BELİRTİLEN Y&Uuml;KSEK MAHKEMELERDEN DEĞİLLERDİR . Y&Uuml;KSEK SE&Ccedil;İM KURULU&rsquo;DA Y&Uuml;KSEK
MAHKEMELERDEN SAYILMAMIŞTIR.<br />
SAYIŞTAY: TBMM adına kamu kurum ve kuruluşlarının b&uuml;t&uuml;n gelir ve giderlerini
inceler ve denetler. SayıştayEın keisn h&uuml;k&uuml;mleri ahkkına ilgililer yazılı
bildirim tarihinden itibaren 15 g&uuml;n i&ccedil;inde bir kereye mahsus olmak &uuml;zere karar
d&uuml;zeltilmesi isteminde bulunabilirler. SayıştayEın kararlarına karşı idari
yargı yoluna bşvurulmaz.<br />
-*Danıştay kararlarıyla Sayıştay kararları &ccedil;atışınsa Danıştay&rsquo;ın kararları esas
alınır.<br />
-*2005 yılında yapılan Anayasa değişiklikleri ise Sayıştay merkezi y&ouml;entim
b&uuml;t&ccedil;esi kapsamındaki kamu idareleri ile sosyal g&uuml;venlik kurumlarının b&uuml;t&uuml;n
gelir ve giderleri ile mallarını TBMM adına denetler.<br />
-*2005 yılında yapılan Anayasa değişiklikleri ile Mahalli idarelerin hesap ve
işlemlerinin denetimi ve kesin h&uuml;kme bağlanması Sayıştay tarafından yapılır<br />
-*2004 yılında yapılan değişiklikler ile Sayıştay silahlı kuvvetlerin elinde
bulunan devlet mallarının denetlemesinin yolu a&ccedil;ılmıştır.</p>
<p >
<strong><span style="text-decoration: underline;">Y&Uuml;KSEK SE&Ccedil;İM KURULU</span></strong><br />
Anayasaya g&ouml;re se&ccedil;imler yargı organlarının genel y&ouml;netimi ve denetimi altında
yapılır. Se&ccedil;imlerin başlamasından bitimine kadar, se&ccedil;imin d&uuml;zen i&ccedil;inde y&ouml;netimi
ve d&uuml;r&uuml;stl&uuml;ğ&uuml;yle ilgili b&uuml;t&uuml;n işlemleri yapmak, se&ccedil;im s&uuml;resince de se&ccedil;imden sonra
se&ccedil;imle ilgili b&uuml;t&uuml;n yolsuzlukları şikayet etme g&ouml;revi Y&uuml;ksek Se&ccedil;im
Kurulu&rsquo;nundur. Y&uuml;ksek Se&ccedil;im Kurulu&rsquo;nun kararları aleyhine başka bir makama
başvurulamaz. Y&uuml;ksek Se&ccedil;im Kurulu yedi asil ve d&ouml;rt yedek &uuml;yeden oluşru.
&uuml;yelerin 6 sı yargıtay, 5 i Danıştay genel kurullarınca kendi &uuml;yeleri arasında
&uuml;ye tamsayılarının salt &ccedil;oğunluğunun gizli oyuyla se&ccedil;ilir. Y&uuml;ksek Se&ccedil;im Kurulu
ğyelerinin g&ouml;rev s&uuml;resi 6 yıldır. s&uuml;resi biten &uuml;yeler yeniden se&ccedil;ilebilir.
Y&uuml;ksek Se&ccedil;im Kurulu anayasada yasama b&ouml;l&uuml;m&uuml;nd ed&uuml;zenlenmiştir. Anayasa
Mahkemesi , tıpkı sayıştay gibi Y&uuml;ksek Se&ccedil;im Kurulu&rsquo;nu da y&uuml;ksek mahkeme olarak
kabul etmemiştir.<br />
<strong>G&Ouml;REVLERİ</strong><br />
*İl ve il&ccedil;e se&ccedil;im kurullarının oluşmasını sağlamak<br />
* il se&ccedil;im kurullarını oluşumuna, işlemlerine ve kaarlarına karşı yapılacak
itirazları, oy verme g&uuml;n&uuml;nden &ouml;nce ve itiraz konusunun gerektirdiği s&uuml;ratle
kesin karara bağlamak<br />
*Adaylığa ait itirazlar hakkında kesin karar vermek.<br />
*İl se&ccedil;im kurullarınca d&uuml;zenlenen tutanaklara karşı yapılan itirazları
inceleyip kesin kara bağlamak.<br />
*T&uuml;rkiye&rsquo;nin ger&ccedil;eklerinden doğmuş bir d&uuml;ş&uuml;nce sistemidir. T&uuml;rk milletinin
iradesiyle oluşmuş, tarihi bir gelişmenin &uuml;r&uuml;n&uuml;d&uuml;r. Atat&uuml;rk&ccedil;&uuml;l&uuml;k, her şeyden
&ouml;nce millete haklarını tanıma ve tanıtmadır; millet egemenliğinin ifadesidir.
Atat&uuml;rk&ccedil;&uuml;l&uuml;k bir kurtuluştur, millet&ccedil;e bağımsızlığa kavuşmadır.<br />
*Atat&uuml;rk&ccedil;&uuml;l&uuml;k, &ccedil;ağdaş uygarlık seviyesine ulaşmadır, batılılaşmadır;bir diğer
anlamda da modernleşmedir; h&uuml;r d&uuml;ş&uuml;nceyi temsil eder, h&uuml;rriyet ve demokrasi
anlayışıdır.<br />
*Atat&uuml;rk&ccedil;&uuml;l&uuml;k, modern bir toplum hayatı yaşama demektir; laik bir d&uuml;zen kurma,
m&uuml;spet bilim zihniyetiyle devleti y&ouml;netmedir. Bu iki anlamıyla Atat&uuml;rk&ccedil;&uuml;l&uuml;k,
T&uuml;rk toplumuna uygun sosyal ve siyasal kurumları kurma ve modern toplum olma
demektir.<br />
* Atat&uuml;rk&ccedil;&uuml;l&uuml;k ilkelerini &ldquo;Temel İlkeler&rdquo; ve &ldquo;B&uuml;t&uuml;nleyici İlkeler&rdquo; olmak &uuml;zere
iki grupta değerlendirmekteyiz. &ldquo;Temel İlkeler&rdquo;: Cumhuriyet&ccedil;ilik,
Milliyet&ccedil;ilik, Halk&ccedil;ılık, Devlet&ccedil;ilik, Laiklik ve İnkıl&acirc;p&ccedil;ılıktır. &ldquo;B&uuml;t&uuml;nleyici
İlkeler&rdquo; ise: Milli Egemenlik, Milli Bağımsızlık, Milli Birlik ve Beraberlik,
&ldquo;Yurtta Sulh, Cihanda Sulh&rdquo;, &Ccedil;ağdaşlaşma, Bilimsellik ve Akılcılık, insan ve
insanlık sevgisidir.</p>
<p><strong><span style="text-decoration: underline;">CUMHURBAŞKANI:</span></strong></p>
<p>Cumhurbaşkanı olabilmenin şartları nelerdir? Milletvekili olma zorunluluğu
var mıdır?</p>
<p>Cumhurbaşkanı, T&uuml;rkiye B&uuml;y&uuml;k Millet Meclisince kırk yaşını doldurmuş ve
y&uuml;ksek&ouml;ğrenim yapmış kendi &uuml;yeleri veya bu niteliklere ve milletvekili se&ccedil;ilme
yeterliğine sahip T&uuml;rk vatandaşları arasından beş yıllık bir s&uuml;re i&ccedil;in se&ccedil;ilir.
Cumhurbaşkanlığına T&uuml;rkiye B&uuml;y&uuml;k Millet Meclisi &uuml;yeleri dışından aday
g&ouml;sterilebilmesi, Meclis &uuml;ye tamsayısının en az beşte birinin yazılı &ouml;nerisiyle
m&uuml;mk&uuml;nd&uuml;r. Cumhurbaşkanı se&ccedil;ilenin, varsa partisi ile ilişiği kesilir ve
T&uuml;rkiye B&uuml;y&uuml;k Millet Meclisi &Uuml;yeliği sona erer. Cumhurbaşkanı, T&uuml;rkiye B&uuml;y&uuml;k
Millet Meclisi &uuml;ye tamsayısının &uuml;&ccedil;te iki &ccedil;oğunluğu ile ve gizli oyla se&ccedil;ilir.
T&uuml;rkiye B&uuml;y&uuml;k Millet Meclisi toplantı halinde değilse hemen toplantıya
&ccedil;ağrılır. Cumhurbaşkanının g&ouml;rev s&uuml;resinin dolmasından otuz g&uuml;n &ouml;nce veya
Cumhurbaşkanlığı makamının boşalmasından on g&uuml;n sonra Cumhurbaşkanlığı se&ccedil;imine
başlanır ve se&ccedil;ime başlama tarihinden itibaren otuz g&uuml;n i&ccedil;inde sonu&ccedil;landırılır.
Bu s&uuml;renin ilk on g&uuml;n&uuml; i&ccedil;inde adayların Meclis Başkanlık Divanına bildirilmesi
ve kalan yirmi g&uuml;n i&ccedil;inde de se&ccedil;imin tamamlanması gerekir. En az &uuml;&ccedil;er g&uuml;n ara
ile yapılacak oylamaların ilk ikisinde &uuml;ye tamsayısının &uuml;&ccedil;te iki &ccedil;oğunluk oyu
sağlanamazsa &uuml;&ccedil;&uuml;nc&uuml; oylamaya ge&ccedil;ilir, &uuml;&ccedil;&uuml;nc&uuml; oylamada &uuml;ye tamsayısının salt
&ccedil;oğunluğunu sağlayan aday Cumhurbaşkanı se&ccedil;ilmiş olur. Bu oylamada &uuml;ye
tamsayısının salt &ccedil;oğunluğu sağlanamadığı takdirde &uuml;&ccedil;&uuml;nc&uuml; oylamada en &ccedil;ok oy
almış bulunan iki aday arasında d&ouml;rd&uuml;nc&uuml; oylama yapılır, bu oylamada da &uuml;ye
tamsayısının salt &ccedil;oğunluğu ile Cumhurbaşkanı se&ccedil;ilemediği takdirde derhal
T&uuml;rkiye B&uuml;y&uuml;k Millet Meclisi se&ccedil;imleri yenilenir. Se&ccedil;ilen yeni Cumhurbaşkanı
g&ouml;reve başlayıncaya kadar g&ouml;rev s&uuml;resi dolan Cumhurbaşkanının g&ouml;revi devam
eder. Cumhurbaşkanı Devletin başıdır. Bu sıfatla T&uuml;rkiye Cumhuriyetini ve T&uuml;rk
Milletinin birliğini temsil eder; Anayasanın uygulanmasını, Devlet organlarının
d&uuml;zenli ve uyumlu &ccedil;alışmasını g&ouml;zetir.</p>
<p>Bu ama&ccedil;larla Anayasanın ilgili maddelerinde g&ouml;sterilen şartlara uyarak
yapacağı g&ouml;rev ve kullanacağı yetkiler şunlardır:</p>
<p style="margin-left: 36pt; text-indent: -18pt;">a)<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span>Yasama
ile ilgili olanlar:</p>
<p style="margin-left: 36pt; text-indent: -18pt;">b)<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span>Gerekli
g&ouml;rd&uuml;ğ&uuml; takdirde, yasama yılının ilk g&uuml;n&uuml; T&uuml;rkiye B&uuml;y&uuml;k Millet Meclisinde
a&ccedil;ılış konuşmasını yapmak,</p>
<p style="margin-left: 36pt; text-indent: -18pt;">c)<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span>T&uuml;rkiye
B&uuml;y&uuml;k Millet Meclisini gerektiğinde toplantıya &ccedil;ağırmak,</p>
<p style="margin-left: 36pt; text-indent: -18pt;">d)<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp; </span>Kanunları
yayımlamak,</p>
<p style="margin-left: 36pt; text-indent: -18pt;">e)<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span>Kanunları
tekrar g&ouml;r&uuml;ş&uuml;lmek &uuml;zere T&uuml;rkiye B&uuml;y&uuml;k Millet Meclisine geri g&ouml;ndermek,</p>
<p style="margin-left: 36pt; text-indent: -18pt;">f)<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span>Anayasa
değişikliklerine ilişkin kanunları gerekli g&ouml;rd&uuml;ğ&uuml; takdirde halkoyuna sunmak,</p>
<p style="margin-left: 36pt; text-indent: -18pt;">g)<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span>Kanunların,
kanun h&uuml;km&uuml;ndeki kararnamelerin, T&uuml;rkiye B&uuml;y&uuml;k Millet Meclisi İ&ccedil;t&uuml;z&uuml;ğ&uuml;n&uuml;n,
t&uuml;m&uuml;n&uuml;n veya belirli h&uuml;k&uuml;mlerinin Anayasaya şekil veya esas bakımından aykırı
oldukları gerek&ccedil;esi ile Anayasa Mahkemesinde iptal davası a&ccedil;mak,</p>
<p style="margin-left: 36pt; text-indent: -18pt;">h)<span style="font-size: 7pt;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span>T&uuml;rkiye
B&uuml;y&uuml;k Millet Meclisi se&ccedil;imlerinin yenilenmesine karar vermek,</p>
<p>b) Y&uuml;r&uuml;tme alanına ilişkin olanlar:</p>
<p>Başbakanı atamak ve istifasını kabul etmek,</p>
<p>Başbakanın teklifi &uuml;zerine bakanları atamak ve g&ouml;revlerine son vermek,</p>
<p>Gerekli g&ouml;rd&uuml;ğ&uuml; hallerde Bakanlar Kuruluna başkanlık etmek veya Bakanlar
Kurulunu başkanlığı altında toplantıya &ccedil;ağırmak,</p>
<p>Yabancı devletlere T&uuml;rk Devletinin temsilcilerini g&ouml;ndermek, T&uuml;rkiye
Cumhuriyetine g&ouml;nderilecek yabancı devlet temsilcilerini kabul etmek,</p>
<p>Milletlerarası antlaşmaları onaylamak ve yayımlamak,</p>
<p>T&uuml;rkiye B&uuml;y&uuml;k Millet Meclisi adına T&uuml;rk Silahlı Kuvvetlerinin
Başkomutanlığını temsil etmek,</p>
<p>T&uuml;rk Silahlı Kuvvetlerinin kullanılmasına karar vermek,</p>
<p>Genelkurmay Başkanını atamak,</p>
<p>Mill&icirc; G&uuml;venlik Kurulunu toplantıya &ccedil;ağırmak,</p>
<p>Mill&icirc; G&uuml;venlik Kuruluna Başkanlık etmek,</p>
<p>Başkanlığında toplanan Bakanlar Kurulu kararıyla sıkıy&ouml;netim veya olağan&uuml;st&uuml;
hal il&acirc;n etmek ve kanun h&uuml;km&uuml;nde kararname &ccedil;ıkarmak,</p>
<p>Kararnameleri imzalamak,</p>
<p>S&uuml;rekli hastalık, sakatlık ve kocama sebebi ile belirli kişilerin cezalarını
hafifletmek veya kaldırmak,</p>
<p>Devlet Denetleme Kurulunun &uuml;yelerini ve Başkanını atamak,</p>
<p>Devlet Denetleme Kuruluna inceleme, araştırma ve denetleme yaptırtmak,</p>
<p>Y&uuml;ksek&ouml;ğretim Kurulu &uuml;yelerini se&ccedil;mek,</p>
<p>&Uuml;niversite rekt&ouml;rlerini se&ccedil;mek,</p>
<p>c) Yargı ile ilgili olanlar:</p>
<p>Anayasa Mahkemesi &uuml;yelerini, Danıştay &uuml;yelerinin d&ouml;rtte birini, Yargıtay
Cumhuriyet Başsavcısı ve Yargıtay Cumhuriyet Başsavcı vekilini, Asker&icirc; Yargıtay
&uuml;yelerini, Asker&icirc; Y&uuml;ksek İdare Mahkemesi &uuml;yelerini, H&acirc;kimler ve Savcılar Y&uuml;ksek
Kurulu &uuml;yelerini se&ccedil;mek.</p>
<p>Cumhurbaşkanı, ayrıca Anayasada ve kanunlarda verilen se&ccedil;me ve atama
g&ouml;revleri ile diğer g&ouml;revleri yerine getirir ve yetkileri kullanır.</p>
<p><strong>Sayıştay:</strong> Sayıştay, merkezi y&ouml;netim b&uuml;t&ccedil;esi kapsamındaki
kamu idareleri ile sosyal g&uuml;venlik kurumlarının b&uuml;t&uuml;n gelir ve giderleri ile
mallarını T&uuml;rkiye B&uuml;y&uuml;k Millet Meclisi adına denetlemek ve sorumluların hesap
ve işlemlerini kesin h&uuml;kme bağlamak ve kanunlarla verilen inceleme, denetleme
ve h&uuml;kme bağlama işlerini yapmakla g&ouml;revlidir. Sayıştayın kesin h&uuml;k&uuml;mleri
hakkında ilgililer yazılı bildirim tarihinden itibaren on beş g&uuml;n i&ccedil;inde bir
kereye mahsus olmak &uuml;zere karar d&uuml;zeltilmesi isteminde bulunabilirler. Bu
kararlar dolayısıyla idar&icirc; yargı yoluna başvurulamaz. Vergi, benzeri mal&icirc;
y&uuml;k&uuml;ml&uuml;l&uuml;kler ve &ouml;devler hakkında Danıştay ile Sayıştay kararları arasındaki
uyuşmazlıklarda Danıştay kararları esas alınır. Mahalli idarelerin hesap ve
işlemlerinin denetimi ve kesin h&uuml;kme bağlanması Sayıştay tarafından yapılır.
Sayıştayın kuruluşu, işleyişi, denetim usulleri, mensuplarının nitelikleri,
atanmaları, &ouml;dev ve yetkileri, hakları ve y&uuml;k&uuml;ml&uuml;l&uuml;kleri ve diğer &ouml;zl&uuml;k işleri,
Başkan ve &uuml;yelerinin teminatı kanunla d&uuml;zenlenir.</p>
<p><strong>Yargıtay:</strong> Yargıtay, adliye mahkemelerince verilen ve
kanunun başka bir adl&icirc; yargı merciine bırakmadığı karar ve h&uuml;k&uuml;mlerin son
inceleme merciidir. Kanunla g&ouml;sterilen belli davalara da ilk ve son derece
mahkemesi olarak bakar. Yargıtay &uuml;yeleri, birinci sınıfa ayrılmış adl&icirc; yargı
h&acirc;kim ve Cumhuriyet savcıları ile bu meslekten sayılanlar arasından H&acirc;kimler ve
Savcılar Y&uuml;ksek Kurulunca &uuml;ye tamsayısının salt &ccedil;oğunluğu ile ve gizli oyla
se&ccedil;ilir. Yargıtay Birinci Başkanı, birinci başkanvekilleri ve daire başkanları
kendi &uuml;yeleri arasından Yargıtay Genel Kurulunca &uuml;ye tamsayısının salt
&ccedil;oğunluğu ve gizli oyla d&ouml;rt yıl i&ccedil;in se&ccedil;ilirler; s&uuml;resi bitenler yeniden
se&ccedil;ilebilirler. Yargıtay Cumhuriyet Başsavcısı ve Cumhuriyet Başsavcı vekili,
Yargıtay Genel Kurulunun kendi &uuml;yeleri arasından gizli oyla belirleyeceği beşer
aday arasından Cumhurbaşkanı tarafından d&ouml;rt yıl i&ccedil;in se&ccedil;ilirler. S&uuml;resi
bitenler yeniden se&ccedil;ilebilirler. Yargıtayın kuruluşu, işleyişi, Başkan,
başkanvekilleri, daire başkanları ve &uuml;yeleri ile Cumhuriyet Başsavcısı ve
Cumhuriyet Başsavcı vekilinin nitelikleri ve se&ccedil;im usulleri, mahkemelerin
bağımsızlığı ve h&acirc;kimlik teminatı esaslarına g&ouml;re kanunla d&uuml;zenlenir.</p>
<p><strong>Danıştay:</strong> Danıştay, idar&icirc; mahkemelerce verilen ve kanunun
başka bir idar&icirc; yargı merciine bırakmadığı karar ve h&uuml;k&uuml;mlerin son inceleme
merciidir. Kanunla g&ouml;sterilen belli davalara da ilk ve son derece mahkemesi
olarak bakar. Danıştay, davaları g&ouml;rmek, Başbakan ve Bakanlar Kurulunca
g&ouml;nderilen kanun tasarıları, kamu hizmetleri ile ilgili imtiyaz şartlaşma ve
s&ouml;zleşmeleri hakkında iki ay i&ccedil;inde d&uuml;ş&uuml;ncesini bildirmek, t&uuml;z&uuml;k tasarılarını
incelemek, idar&icirc; uyuşmazlıkları &ccedil;&ouml;zmek ve kanunla g&ouml;sterilen diğer işleri
yapmakla g&ouml;revlidir. Danıştay &uuml;yelerinin d&ouml;rtte &uuml;&ccedil;&uuml;, birinci sınıf idar&icirc; yargı
h&acirc;kim ve savcıları ile bu meslekten sayılanlar arasından H&acirc;kimler ve Savcılar
Y&uuml;ksek Kurulu; d&ouml;rtte biri, nitelikleri kanunda belirtilen g&ouml;revliler arasından
Cumhurbaşkanı; tarafından se&ccedil;ilir. Danıştay Başkanı, Başsavcı, başkanvekilleri
ve daire başkanları, kendi &uuml;yeleri arasından Danıştay Genel Kurulunca &uuml;ye
tamsayısının salt &ccedil;oğunluğu ve gizli oyla d&ouml;rt yıl i&ccedil;in se&ccedil;ilirler. S&uuml;resi
bitenler yeniden se&ccedil;ilebilirler. Danıştayın, kuruluşu, işleyişi, Başkan,
Başsavcı, başkanvekilleri, daire başkanları ile &uuml;yelerinin nitelikleri ve se&ccedil;im
usulleri, idar&icirc; yargının &ouml;zelliği, mahkemelerin bağımsızlığı ve h&acirc;kimlik
teminatı esaslarına g&ouml;re kanunla d&uuml;zenlenir.</p>
<p>Yasama yetkisi: Yasama yetkisi T&uuml;rk Milleti adına T&uuml;rkiye B&uuml;y&uuml;k Millet
Meclisinindir. Bu yetki devredilemez.</p>
<p>Y&uuml;r&uuml;tme yetkisi ve g&ouml;revi: Y&uuml;r&uuml;tme yetkisi ve g&ouml;revi, Cumhurbaşkanı ve
Bakanlar Kurulu tarafından, Anayasaya ve kanunlara uygun olarak kullanılır ve
yerine getirilir.</p>
<p>Yargı yetkisi: Yargı yetkisi, T&uuml;rk Milleti adına bağımsız mahkemelerce
kullanılır.</p>
<p><strong><span style="text-decoration: underline;">KURTULUŞ SAVAŞI HAZIRLIK D&Ouml;NEMİ</span></strong><br />
-Mustafa Kemal in samsuna &ccedil;ıkması:Samsun raporunda; B&ouml;lgedeki olayların Rum
&ccedil;eteler tarafından &ccedil;ıkarıldığını İngilizlerin Samsun u haksız yere işgal
ettiğini a&ccedil;ıklamıştır.<br />
<strong><span style="text-decoration: underline;">HAVZA GENELGESİ</span></strong>(28 mAYIS 1919):mONDROS A KARŞI
&Ccedil;IKILMIŞTIR.<br />
Ulusal bilin&ccedil; uyundurulmaya &ccedil;alışılmıştır.<br />
<strong><span style="text-decoration: underline;">AMASYA GENELGESİ</span></strong> (22 Haziran 1919): Asıl ama&ccedil; ulusal
bağımsızlığı ger&ccedil;ekleştirmek olmasına karşın ulusal egemenlik anlayışını da
i&ccedil;ermektedir. ileride nasıl bir y&ouml;netim kurulacağının ifucudur.<br />
ULUSUN BAĞIMSIZLIĞINI, YİNE ULUSUN AZİM VE KARARI KURTARACAKTIR.<br />
Mondros Ateşkesine a&ccedil;ık bir şekilde karşı &ccedil;ıkılmıştır.<br />
Amasya Genelgesinden sonra 7-8 Temmuz gecesi, Mustafa Kemal g&ouml;revden alındı,
Mustafa Kemal de g&ouml;revinden istifa etti.<br />
<strong><span style="text-decoration: underline;">ERZURUM KONGRESİ</span></strong> (28 TEMMUZ -7 AĞUSTOS 1919)<br />
Temsil kurulu se&ccedil;ilmiştir. EN SONUMUT SONUCUDUR.<br />
Mustafa Kemal kurtuluş Savaşında lider durumuna getirmiştir.<br />
Meclisi Mebusanın toplanması istenmiştirn. Mustafa Kemal in sivil olarak
katıldığı ilk kongredir. iki &uuml;ye istifa ederek yerlerine Mustafa Kemal
se&ccedil;ilmiştir.<br />
<strong><span style="text-decoration: underline;">TEMSİL HEYETİ:</span></strong> İLK defa Erzurum Kongresinde ortaya
&ccedil;ıkmış, Sivas Kongresinde &uuml;ye sayısı arttırılmıştır. TBMM a&ccedil;ılıncaya kadar
Kurtuluş Savaşını y&uuml;r&uuml;tm&uuml;şt&uuml;r. Başkanı MUSTAFA KEMAL DİR.<br />
<strong><span style="text-decoration: underline;">SİVAS KONGRESİ</span></strong> (4-11 EYL&Uuml;L 1919)<br />
Erzurum Kongresi kararlarını temel olarak genişletmiştir.<br />
Kongrenin a&ccedil;ılmasında başkanlık ve Manda sorunu yaşamnmıştır.<br />
Anadolu draki t&uuml;m ulusal g&uuml;&ccedil;ler birleştirilmiştir.<br />
Sivas Kongresinin en &ouml;nemli sonu&ccedil;larından biri Damat Ferit h&uuml;k&uuml;metinin istifa
ettirilmesidir. Anadolu hareketinin İstanbul h&uuml;k&uuml;metine karşı kazandığı ilk
siyasi başarıdır.<br />
<strong><span style="text-decoration: underline;">AMASYA G&Ouml;R&Uuml;ŞMELERİ</span></strong> (20-22 EKİM 1919)<br />
İstanbul h&uuml;k&uuml;meti, Temsil Kurulunu resmen tanımış oluyordu.<br />
İstanbul h&uuml;k&uuml;meti ve Temsil Kurulu ilk kez birlikte hareket etmişlerdir.<br />
İkisi gizli beş protokol yapılmıştır. ancak İstanbul h&uuml;k&uuml;meti se&ccedil;imlerin
yapılması dışında alınan kararlara uymamıştır.<br />
-Mustafa Kemal in Ankara yı merkez se&ccedil;mesi<br />
-Son Osmanlı Mebusan Meclisinin A&ccedil;ılması (12 OCAK 1920)<br />
MİSAK-I MİLLİ (ULUSAL ANT) (28 OCAK 1920)<br />
(İSTANBUL İTİLAF DEVLETLERİ TARAFINDANRESMEN İŞGAL EDİLMİŞTİR)<br />
(ANKARA DA TBMM A&Ccedil;ILMASINA NEDEN OLMUŞTUR)<br />
-T&uuml;rk yurdunun sınırları &ccedil;izilmiştir.<br />
-Kurtuluş Savaşının programı oluşmuştur.<br />
-Sorunlara, barış&ccedil;ı &ccedil;&ouml;z&uuml;m &ouml;nermiştir.<br />
-meclis kararlarıdır. Tam bağımsızlık istenmiştir.<br />
-Padişah onallamamıştır.<br />
-D&uuml;nyadaki &uuml;lkelerin meclislerini duyurulması kararlaştırılmıştır.<br />
<strong><span style="text-decoration: underline;">TBMM NİN A&Ccedil;ILMASI</span></strong> (23 NİSAN 1920 )<br />
Meclisi Mebusanın kapatılması &uuml;zerine ortaya &ccedil;ıkan parlamento boşluğunu
doldurmak<br />
-Ulusal bağımsızlık ve egemenliği sağlamaktır.<br />
ALINAN İLK KARARLAR (24 NİSAN 1920)<br />
-padişahtan bağımsız olması ama&ccedil;landı.<br />
-Osmanlı Saltanatının yok sayılması na karar verildi.<br />
- TBMM yasama ve y&uuml;r&uuml;tme yetkilerini kendinde topladı<br />
(ama&ccedil; savaş koşullarında alınacak kararların hızlandırılmasıdır. )<br />
-Meclis H&uuml;k&uuml;meti sistemi kabul edilmiş oluyordu.<br />
1921 ANAYASASI İLE HUKUKİ GER&Ccedil;ERLİLİK DE KAZANACAKTIR.<br />
-Temsil Kurulunun g&ouml;revini sona erdirmiştir.<br />
-Hıyanet-i Vataniye Yasası &ccedil;ıkarıldı.<br />
-Kurtuluş tekirdağ-yozgat<br />
23 Mart 2009 10:41 D&uuml;zenle Sil<br />
-Kurtuluş Savaşını y&uuml;r&uuml;tm&uuml;ş &uuml;yeleri istiklal mahkemelerinde g&ouml;rev almış 23
NİSAN 1920 &ndash; 1 NİSAN 1923 tarihleri arasında g&ouml;rev yapmış ve saltanatı
kaldırmıştır.<br />
<strong><span style="text-decoration: underline;">1.TBMM nin İlk Kanunları</span></strong><br />
&mdash;TBMM, mille m&uuml;cadeleye kaynak sağlamak i&ccedil;in k&uuml;&ccedil;&uuml;kbaş (ağnam) hayvanlardan
alınan vergiyi artırmıştır. Bunun yanında Hıyaneti Vataniye kanununu
&ccedil;ıkarılarak otoritesi g&uuml;&ccedil;lendirilmiştir. Kanunu gevrek&ccedil;esi asker ka&ccedil;aklarının
artmaksı ve ayaklanmaların &ccedil;ıkmasıdır.<br />
Firariler hakkında kunun &ccedil;ıkarılarak askerden ka&ccedil;anları yargılamak &uuml;zere
istiklal Mahkemeleri kurulmuştur.<br />
SEVR BARIŞ ANTLAŞMASI (10 Ağustos 1920)<br />
-Osmanlı Parlamentosunda onaylanmadığından hukuken ge&ccedil;ersizdir.<br />
- Kurtuluş Savaşı kazanıldığı i&ccedil;in uygulanmamıştır.<br />
-TBMM antlaşmayı tanımadığı gibi imzalayanları da vatan haini ilan etmiştir.<br />
-Antlaşmanın amaıcı T&uuml;rk ulusuna son vermekti. Bu durum ise T&uuml;rk ulusunun
bağımsızlık m&uuml;cadelesini hızlandıracaktır.<br />
(BATILI DEVLETLERİN OSMANLI Devletini nasıl paylaşacakları tartışmasının
uzaması diğer antlaşmalara g&ouml;re daha ge&ccedil; imzalanmasına neden olmuştur.)</p>
<p >
<strong>MUHAREBELER D&Ouml;NEMİ</strong><br />
DOĞU CEPHESİ<br />
G&Uuml;NEY CEPHESİ<br />
BATI CEPHESİ<br />
DOĞU CEPHESİ:<br />
-TBMM NİN A&Ccedil;TIĞI İLK CEPHEDİR.<br />
-eRMENİ VE g&Uuml;RC&Uuml;LER 1. D&uuml;nya savaşı bunulımından yararlanarak;Kars, Ardahan ve
Batum u işgal etmişlerdi.<br />
(T&uuml;rk ordusunun başarısı ile G&Uuml;MR&Uuml; BARIŞI YAPILMIŞTIR..&rdquo;ERMENİLERLE&rdquo;)<br />
_Kars ve &ccedil;evresi T&uuml;rklere geri verildi.<br />
-Ermenistan Misak ı Milliyi tanıdı.<br />
-TBMM Yİ tanıyan ve Sevr den vazge&ccedil;en ilk devlet Ermenistan dır<br />
-TBMM nin imzaladığı ilk anlaşmadır.<br />
(TBMM NİN ULUSLARARASI ALANDA İLK BAŞARISIDIR)<br />
G&Uuml;NEY CEPHESİ:(FRANSA İLE ANKARA ANTLAŞMASI 20 EKİM 1921 İLE SONA ERMİŞ VE
G&Uuml;NEY SINIRI &Ccedil;İZİLMİŞTİR.<br />
BATI CEPHESİ: TBMM nin kurduğu d&uuml;zenli ordu savaşmıştır.<br />
yunanlılara karşı a&ccedil;ılmıştır<br />
En b&uuml;y&uuml;k maharebeler burda verilmiştir. bu muharebeler 1. ve 2. in&ouml;n&uuml;
savaşları, k&uuml;tahya, eskişehir savaşları, Sakarya Meydan Savaşı ve B&uuml;y&uuml;k Taarruz
dur..<br />
<strong><span style="text-decoration: underline;">1. İN&Ouml;N&Uuml; SAVAŞI (6-10 OCAK 1921 )</span></strong><br />
SAVAŞI TBMM ordusu kazanmıştır<br />
-yeni kuruluna d&uuml;zenli ordunun ilk başarısıdır.<br />
-Halkın TBMM ye olan g&uuml;veni artmıştır.<br />
- Savaş sonrasi ilk Anayasa kabul edildi. (20 ocak 1921)<br />
-iSTİKLAL marşı kabul edildi.<br />
-İtilaf devletleri LONDRO KONFERANSINI TOPLADI<br />
<strong><span style="text-decoration: underline;">LONDRA KONFERANSI</span></strong> (21 Şubat -12 Mart 1921)<br />
ama&ccedil;; servi değiştirip TBMM ye kabul ettirmektir<br />
-TBMM İSE mİSAK I mİLLİ Yİ D&Uuml;NYA KAMU OYUNA KABUL ETTİRMEK İ&Ccedil;İN KATILDI.<br />
-iTİLAF DEVLETLERİ tbmm yi ilk kez resmen tanımış oldular.<br />
<strong>MOSKOVA ANTLAŞMASI</strong>(16 Mart 1921)<br />
-Sovyet Rusya ile imzalandı.<br />
-Her iki devlet eski anlaşmaları ge&ccedil;ersiz saydı<br />
B&Ouml;YLECE SOVYET RUSYA KAPİT&Uuml;LASYON HAKKINDAN İLK VAZGE&Ccedil;EN DEVLET OLDU.<br />
-Misak ı Milli yi ilk tanıyan b&uuml;y&uuml;k devlet oldu.<br />
-Batum ilk taviz verildi<br />
-doğu sınırı g&uuml;vence altına alındı.<br />
<strong>2. İN&Ouml;N&Uuml; SAVAŞI 822-31 MART 1921 )</strong><br />
Yunanlıların 1. in&ouml;n&uuml; mağlubiyetinin izlerini silmek istemesi<br />
<strong>ESKİŞEHİR K&Uuml;TAHYA SAVAŞLARI (10 -24 TEMMUZ 1921)</strong><br />
_TBMM ordusu sakarya nehrinin doğusuna &ccedil;ekildi.<br />
-Mustafa Kemal Başkomutanlığa g2etirildi<br />
- Tekalif i Milliye Yasası &ccedil;ıkarıldı.<br />
Başkomutanlık Kanunu:Mustafa kemal in ordunun başına geniş yetkilerle ge&ccedil;mesi
olarak belirlenmiştir.<br />
<strong>TEKALİF İ MİLLİYE EMİRLERİ</strong><br />
-SAKARYA SAVAŞI ( 23 AĞUSTOS-12EYL&Uuml;L 1921)<br />
-Yunanlıların son saldırı savaşı oldu.<br />
-mUSTAFA K. E gazilik ve Mareşallik r&uuml;tbesi verildi.<br />
-Kars antlaşması imzalandı.<br />
-Ankara Antlaşması imzalandı<br />
-T&uuml;rklerin geri &ccedil;ekilişi sona erdi.<br />
<strong>KARS ANTLAŞMASI</strong><br />
-Sakarya savaşxından sonra imzalanmıştır<br />
-TBMM İLE sovyet Rusya, denetimi altındoa<br />
-Dostluk antlaşmasıdır<br />
-Doğu sınırı kesinleşmiştir<br />
ANKARA ANTLAŞMASI ( 20 Ekim 1921)<br />
&ldquo;TBMM Yİ TANIYAN İLK İTİLAF DEVLETİ fRANSA OLMUŞTUR&rdquo;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p><strong><span style="text-decoration: underline;">ATAT&Uuml;RK&rsquo;&Uuml;N KENDİ İFADESİYLE İLKELERİNİN TANIMI</span></strong><br />
I.TEMEL İLKELER<br />
<strong><span style="text-decoration: underline;">1-Cumhuriyet&ccedil;ilik</span></strong><br />
-T&uuml;rk milletinin karakter ve adetlerine en uygun olan idare, Cumhuriyet
idaresidir.(1924)<br />
-Cumhuriyet rejimi demek, demokrasi sistemiyle devlet şekli demektir. (1933)<br />
-Cumhuriyet, y&uuml;ksek ahlaki değer ve niteliklere dayanan bir idaredir.
Cumhuriyet fazilettir&hellip; (1925)<br />
-Bug&uuml;nk&uuml; h&uuml;k&uuml;metimiz, devlet teşkilatımız doğrudan doğruya milletin kendi
kendine, kendiliğinden yaptığı bir devlet ve h&uuml;k&uuml;met teşkilatıdır ki, onun adı
cumhuriyet&rsquo;tir. Artık h&uuml;k&uuml;met ile millet arasında ge&ccedil;mişteki ayrılık
kalmamıştır. H&uuml;k&uuml;met millet ve millet h&uuml;k&uuml;mettir. (1925)<br />
<strong><span style="text-decoration: underline;">2-Milliyet&ccedil;ilik:</span></strong><br />
-T&uuml;rkiye Cumhuriyeti&rsquo;ni kuran T&uuml;rk halkına T&uuml;rk Milleti denir. (1930)<br />
-Diyarbakırlı, Vanlı, Erzurumlu, Trakyalı, hep bir soyun evlatları ve aynı
cevherin damarlarıdır. (1923)<br />
-Biz doğrudan doğruya milliyetperveriz ve T&uuml;rk milliyet&ccedil;isiyiz.
Cumhuriyetimizin dayanağı T&uuml;rk toplumudur. Bu toplumun fertleri ne kadar T&uuml;rk
k&uuml;lt&uuml;r&uuml;yle dolu olursa, o topluma dayanan Cumhuriyet de o kadar kuvvetli olur.
(1923)<br />
<strong><span style="text-decoration: underline;">3-Halk&ccedil;ılık:</span></strong><br />
-İ&ccedil; siyasetimizde ilkemiz olan halk&ccedil;ılık, yani milletin bizzat kendi geleceğine
sahip olması esası Anayasamızla tespit edilmiştir. (1921)<br />
-Halk&ccedil;ılık, toplum d&uuml;zenini &ccedil;alışmaya, hukuka dayandırmak isteyen bir toplum
sistemidir. (1921)<br />
-T&uuml;rkiye Cumhuriyeti halkını ayrı ayrı sınıflardan oluşmuş değil, fakat kişisel
ve sosyal hayat i&ccedil;in işb&ouml;l&uuml;m&uuml; itibariyle &ccedil;eşitli mesleklere ayrılmış bir toplum
olarak g&ouml;rmek esas prensiplerimizdendir. (1923)<br />
<strong><span style="text-decoration: underline;">4-Devlet&ccedil;ilik:</span></strong><br />
-Devlet&ccedil;iliğin bizce anlamı şudur: kişilerin &ouml;zel teşebb&uuml;slerini ve şahsi
faaliyetlerini esas tutmak, fakat b&uuml;y&uuml;k bir milletin ve geniş bir memleketin
ihtiya&ccedil;larını ve &ccedil;ok şeylerin yapılmadığını g&ouml;z &ouml;n&uuml;nde tutarak, memleket
ekonomisini devletin eline almak. (1936)<br />
-Prensip olarak, devlet ferdin yerine ge&ccedil;memelidir. Fakat ferdin gelişmesi i&ccedil;in
genel şartları g&ouml;z &ouml;n&uuml;nde bulundurmalıdır. (1930)<br />
-Kesin zaruret olmadık&ccedil;a, piyasalara karışılmaz; bununla beraber, hi&ccedil;bir piyasa
da başıboş değildir. (1937)<br />
5-Laiklik:<br />
-Laiklik, yalnız din ve d&uuml;nya işlerinin ayrılması demek değildir. B&uuml;t&uuml;n
yurttaşların vicdan, ibadet ve din h&uuml;rriyeti de demektir. (1930)<br />
-Laiklik, asla dinsizlik olmadığı gibi, sahte dindarlık ve b&uuml;y&uuml;c&uuml;l&uuml;kle m&uuml;cadele
kapısını a&ccedil;tığı i&ccedil;in, ger&ccedil;ek dindarlığın gelişmesi imk&acirc;nını temin etmiştir.
(1930)<br />
-Din bir vicdan meselesidir. Herkes vicdanının emrine uymakta serbesttir. Biz
dine saygı g&ouml;steririz. D&uuml;ş&uuml;n&uuml;şe ve d&uuml;ş&uuml;nceye karşı değiliz. Biz sadece din
işlerini, millet ve devlet işleriyle karıştırmamaya &ccedil;alışıyor, kasıt ve fiile
dayanan tutucu hareketlerden sakınıyoruz. (1926)<br />
<strong><span style="text-decoration: underline;">6-İnkıl&acirc;p&ccedil;ılık:</span></strong><br />
-Yaptığımız ve yapmakta olduğumuz inkıl&acirc;pların gayesi T&uuml;rkiye Cumhuriyeti
halkını tamamen &ccedil;ağdaş ve b&uuml;t&uuml;n anlam ve g&ouml;r&uuml;şleriyle medeni bir toplum haline
ulaştırmaktır. (1925)<br />
-Biz b&uuml;y&uuml;k bir inkıl&acirc;p yaptık. Memleketi bir &ccedil;ağdan alıp yeni bir &ccedil;ağa
g&ouml;t&uuml;rd&uuml;k. (1925)<br />
<strong>II- B&Uuml;T&Uuml;NLEYİCİ İLKELER</strong><br />
1-Milli Egemenlik:<br />
- Yeni T&uuml;rkiye devletinin yapısının ruhu milli egemenliktir; milletin kayıtsız şartsız
egemenliğidir. Toplumda en y&uuml;ksek h&uuml;rriyetin, en y&uuml;ksek eşitliğin ve adaletin
sağlanması, istikrarı ve korunması ancak ve ancak tam ve kesin anlamıyla milli
egemenliği sağlamış bulunmasıyla devamlılık kazanır. Bundan dolayı h&uuml;rriyetin
de, eşitliğin de, adaletin de dayanak noktası milli egemenliktir. (1923)<br />
2-Milli Bağımsızlık:<br />
-Tam bağımsızlık denildiği zaman, elbette siyasi, mali, iktisadi, adli, askeri,
k&uuml;lt&uuml;rel ve benzeri her hususta tam bağımsızlık ve tam serbestlik demektir. Bu
saydıklarımın herhangi birinde bağımsızlıktan mahrumiyet, millet ve memleketin
ger&ccedil;ek anlamıyla b&uuml;t&uuml;n bağımsızlığından mahrumiyeti demektir. (1921)<br />
-T&uuml;rkiye devletinin bağımsızlığı mukaddestir. O ebediyen sağlanmış ve korunmuş
olmalıdır. (1923)<br />
3-Milli Birlik ve Beraberlik:<br />
- Millet ve biz yok, birlik halinde millet var. Biz ve millet ayrı ayrı şeyler
değiliz. (1919)<br />
Biz milli varlığın temelini, milli şuurda ve milli birlikte g&ouml;rmekteyiz. (1936)<br />
Toplu bir milleti istila etmek, daima dağınık bir milleti istila etmek gibi kolay
değildir. (1919)<br />
4-Yurtta Sulh (Barış), Cihanda Sulh:<br />
-Yurtta sulh, cihanda sulh i&ccedil;in &ccedil;alışıyoruz. (1931)<br />
-T&uuml;rkiye Cumhuriyeti&rsquo;nin en esaslı prensiplerinden biri olan yurtta sulh,
cihanda sulh gayesi, insaniyetin ve medeniyetin refah ve telakisinde en esaslı
amil olsa gerekir. (1919)<br />
-Sulh milletleri refah ve saadete eriştiren en iyi yoldur. (1938)<br />
5-&Ccedil;ağdaşlaşma:<br />
-Milletimizi en kısa yoldan medeniyetin nimetlerine kavuşturmaya, mesut ve
m&uuml;reffeh kılmaya &ccedil;alışacağız ve bunu yapmaya mecburuz. (1925)<br />
-Biz batı medeniyetini bir taklit&ccedil;ilik yapalım diye almıyoruz. Onda iyi olarak
g&ouml;rd&uuml;klerimizi, kendi b&uuml;nyemize uygun bulduğumuz i&ccedil;in, d&uuml;nya medeniyet seviyesi
i&ccedil;inde benimsiyoruz. (1926)<br />
6-Bilimsellik ve Akılcılık:<br />
a) Bilimsellik: D&uuml;nyada her şey i&ccedil;in, medeniyet i&ccedil;in, hayat i&ccedil;in, başarı i&ccedil;in
en ger&ccedil;ek yol g&ouml;sterici bilimdir, fendir. (1924)<br />
T&uuml;rk milletinin y&uuml;r&uuml;mekte olduğu ilerleme ve medeniyet yolunda, elinde ve
kafasında tuttuğu meşale, m&uuml;spet bilimdir. (1933)<br />
b) Akılcılık: Bizim, alık, mantık, zek&acirc;yla hareket etmek en belirgin
&ouml;zelliğimizdir. (1925)<br />
Bu d&uuml;nyada her şey insan kafasından &ccedil;ıkar. (1926)<br />
7-İnsan ve İnsanlık Sevgisi:<br />
-İnsanları mesut edeceğim diye onları birbirine boğazlatmak insanlıktan uzak ve
son derece &uuml;z&uuml;l&uuml;necek bir sistemdir. İnsanları mesut edecek yeg&acirc;ne vasıta,
onları birbirlerine yaklaştırarak, onlara birbirlerini sevdirerek, karşılıklı
maddi ve manevi ihtiya&ccedil;larını temine yarayan hareket ve enerjidir. (1931)<br />
-Biz kimsenin d&uuml;şmanı değiliz. Yalnız insanlığın d&uuml;şmanı olanların d&uuml;şmanıyız.
(1936)</p>
<p >
<strong><em><span style="text-decoration: underline;">ATAT&Uuml;RK İNKILAPLARI (DEVRİMLERİ)</span></em></strong><br />
I-Siyasi alanda yapılan inkıl&acirc;plar:<br />
1- Saltanatın Kaldırılması (1 Kasım 1922)<br />
2- Cumhuriyet&rsquo;in ilanı (29 Ekim 1923)<br />
3- Halifeliğin Kaldırılması (3 Mart 1924)<br />
II-Toplumsal yaşayışın d&uuml;zenlenmesi:<br />
1- Şapka İktisası (giyilmesi) Hakkında Kanun (25 Kasım 1925)<br />
2- Tekke ve Zaviyelerle T&uuml;rbelerin Seddine (kapatılmasına) ve T&uuml;rbedarlıklar
ile Birtakım Unvanların Men ve İlgasına Dair Kanun (30 Kasım 1925)<br />
3- Beynelmilel Saat ve Takvim Hakkındaki Kanunların Kabul&uuml; (26 Aralık 1925). Kabul
edilen bu kanunlarla Hicri ve Rumi Takvim uygulaması kaldırılarak yerine Miladi
Takvim, alaturka saat yerine de milletlerarası saat sistemi uygulaması
benimsenmiştir.<br />
4- &Ouml;l&ccedil;&uuml;ler Kanunu (1 Nisan 1931). Bu kanunla &ouml;l&ccedil;&uuml; birimi olarak medeni
milletlerin kullandıkları metre, kilogram ve litre kabul edilmiştir.<br />
5- Lakap ve Unvanların Kaldırıldığına Dair Kanun (26 Kasım 1934)<br />
6- Bazı Kisvelerin Giyilemeyeceğine Dair Kanun (3 Aralık 1934). Bu kanunla din
adamlarının, hangi dine mensup olurlarsa olsunlar, mabet ve ayinler dışında
ruhani kisve (giysi) taşımaları yasaklanmıştır.<br />
7- Soyadı Kanunu (21 Haziren 1934)<br />
8- Kemal &Ouml;z Adlı Cumhur reisimize Atat&uuml;rk Soyadı Verilmesi Hakkında Kanun (24
Kasım 1934)<br />
9- Kadınların medeni ve siyasi haklara kavuşması:<br />
a- Medeni Kanun&rsquo;la sağlanan haklar<br />
b- Belediye se&ccedil;imlerinde kadınlara se&ccedil;me ve se&ccedil;ilme hakkı tanıyan kanunun
kabul&uuml; (3 Nisan 1930)<br />
c- Anayasa&rsquo;da yapılan değişiklerle kadınlara milletvekili se&ccedil;me ve se&ccedil;ilme
hakkının tanınması (5 Aralık 1934)<br />
III- Hukuk alanında yapılan inkıl&acirc;plar:<br />
1- Şeriye Mahkemelerinin kaldırılması ve Yeni Mahkemeler Teşkilatının Kurulması
Kanunu (8 Nisan 1934)<br />
2- T&uuml;rk Medeni Kanunu (17 Şubat 1926)<br />
Dini hukuk sisteminden ayrılarak laik &ccedil;ağdaş hukuk sisteminin uygulanmasına
başlanmıştır.<br />
IV-Eğitim ve K&uuml;lt&uuml;r alanında yapılan inkıl&acirc;plar:<br />
1- Tevhid-i Tedrisat Kanunu (3 Mart 1924). Bu kanunla T&uuml;rkiye dahilindeki b&uuml;t&uuml;n
bilim ve &ouml;ğretim kurumları Milli Eğitim Bakanlığı&rsquo;na bağlanmıştır.<br />
2- Yeni T&uuml;rk Harflerinin Kabul ve Tatbiki Hakkında Kanun (1 Kasım 1928)<br />
3- T&uuml;rk Tarihi Tetkik Cemiyeti&rsquo;nin Kuruluşu (12 Nisan 1931). Cemiyet daha sonra
T&uuml;rk Tarih Kurumu adını almıştır (3 Ekim 1935). K&uuml;lt&uuml;r alanında yeni bir tarih
g&ouml;r&uuml;n&uuml;ş&uuml;n&uuml; ifade eden kurumun kuruluşuyla &uuml;mmet tarihi anlayışından millet
tarihi anlayışına ge&ccedil;ilmiştir.<br />
4- T&uuml;rk Dili Tetkik Cemiyeti&rsquo;nin kuruluşu (12 Temmuz 1932). Cemiyet daha sonra
T&uuml;rk Dil Kurumu adını almıştır (24 Ağustos 1936). Kurumun amacı, T&uuml;rk dilinin
&ouml;z g&uuml;zelliğini ve zenginliğini meydana &ccedil;ıkarmak, onu d&uuml;nya dilleri arasında
değerine yaraşır y&uuml;ksekliğe eriştirmektir.<br />
5- İstanbul Dar&uuml;lf&uuml;nunu&rsquo;nun kapatılmasına Milli Eğitim Bakanlığı&rsquo;nca yeni bir
&uuml;niversite kurulmasına dair kanun (31 Mayıs 1933). İstanbul &Uuml;niversitesi 18
Kasım 1933 g&uuml;n&uuml; &ouml;ğretime a&ccedil;ılmıştır</p>
<p class="MsoNormal"><strong><span style="text-decoration: underline;">T&uuml;rkiye&rsquo;nin
komşuları &ndash; Başkentleri: </span></strong></p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">&Uuml;lkemizin sınırları itibariyle sekiz komşu &uuml;lkesi
bulunmaktadır. 8333 kmlik sahil uzunluğuna sahip olan &uuml;lkemizde komşu &uuml;lke
olarak en uzun sınırımız Suriye, en kısa sınırımız ise Nahcivan iledir.</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">turkiyenin komsulari T&uuml;rkiyenin Komşuları Hangileridir? T&uuml;rkiyenin
Komşu &Uuml;lkeleri</p>
<p class="MsoNormal">Doğu komşuları</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">G&uuml;rcistan: T&uuml;rkiye ile ekonomik ilişkiler i&ccedil;inde de bulunan
G&uuml;rcistan, T&uuml;rkiye&rsquo;den hem ithalat yapmakta hem de ihracat yapmaktadır.
Başkenti Tiflis&rsquo;tir.</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">Ermenistan: SSCB&rsquo;ye bağlı iken bu birliğin 1991 yılında
dağılmasıyla bağımsızlığını kazanan Ermenistan&rsquo;ın başkenti Erivan&rsquo;dır.
Azerbaycan&rsquo;a ait bir b&ouml;lge olarak kabul edilmiş olan Dağlık Karabağ b&ouml;lgesinin
%20&prime;sini işgal etmesinden dolayı T&uuml;rkiye, bu &uuml;lke ile sınırlarını kapatmıştır.</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">Nahcivan: i&ccedil; işlerinde &ouml;zerk, dış işlerinde ise Azerbaycan&rsquo;a
bağlı bir b&ouml;lge olan &uuml;lkenin başkenti de Nahcıvan&rsquo;dır</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">İran: T&uuml;rkiye&rsquo;nin komşuları arasında, y&uuml;z&ouml;l&ccedil;&uuml;m&uuml; T&uuml;rkiye&rsquo;den
b&uuml;y&uuml;k olan tek &uuml;lke olan İran&rsquo;ın başkenti Tahran.</p>
<p class="MsoNormal">G&uuml;neydoğu komşusu</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">Irak: petrol zenginliği ve tarıma elverişliliği nedeniyle
olduk&ccedil;a jeopolitik bir &ouml;neme sahip olan Irak, İran&rsquo;dan sonra y&uuml;z&ouml;l&ccedil;&uuml;m&uuml; en geniş
&uuml;lkedir. Başkenti ise Bağdat&rsquo;tır.</p>
<p class="MsoNormal">G&uuml;ney komşusu</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">Suriye: başkenti Şam</p>
<p class="MsoNormal">Batı komşuları</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">Bulgaristan; başkenti Sofya</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">Yunanistan; başkenti Atina</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal"><strong><span style="text-decoration: underline;">COĞRAFYA</span></strong><br />
<strong>İ&ccedil; Anadolu B&ouml;lgesi:</strong><br />
Dağları: Karacadağ, Melendiz, Hasandağı, Erciyes, Tahtalı, Tecer, Yıldız, Ak
Dağları, Sundiken ve Sivrihisar Dağları<br />
Platoları: Haymana, Cihanbeyli, Obruk<br />
G&ouml;lleri: Tuz, Eber, Akşehir, &Ccedil;avuş&ccedil;u, Seyfe, Sultan sazlığı, Tuzla ve Acıg&ouml;l<br />
Akarsuları: Kızılırmak, Delice &Ccedil;ayı, &Ccedil;ekerek Suyu, Ankara &Ccedil;ayı, Porsuk &Ccedil;ayı<br />
Tarım &Uuml;r&uuml;nleri: buğday, arpa, yulaf, şeker pancarı, baklagiller, patates, elma<br />
Yeraltı Zenginlikleri: florid , krom, linyit, bakır, &ccedil;inko, kurşun, manganez,
jips, mika, l&uuml;letaşı<br />
<strong>Karadeniz B&ouml;lgesi:</strong><br />
Dağları: Ilgaz, Canik, Bolu, K&ouml;roğlu, Yalnız&ccedil;am, &Ccedil;imen, Mescit, K&uuml;re, Bolu ve
Doğu Karadeniz Dağları<br />
Ovaları: &Ccedil;arşamba, Bafra<br />
G&ouml;lleri: Tortum, Abant Yedi G&ouml;ller, Borabay, Sera<br />
Tarım &Uuml;r&uuml;nleri: Fındık, &ccedil;ay, mısır, t&uuml;t&uuml;n, şeker pancarı, keten, kenevir, fasulye,
pirin&ccedil;, buğday, &ccedil;eltik<br />
Yeraltı Zenginlikleri: bakır, maden k&ouml;m&uuml;r&uuml;, linyit<br />
<strong>Marmara B&ouml;lgesi:</strong><br />
Dağları: Yıldız, Koru, Biga, Kaz, Kapı, Işıklar, Uludağ<br />
Tarım &Uuml;r&uuml;nleri: ay&ccedil;i&ccedil;eği, buğday, t&uuml;t&uuml;n, şeker pancarı, pamuk, mısır, fındık,
zeytin, pirin&ccedil; patates,<br />
Yeraltı Zenginlikleri:<br />
&Ouml;nemli Tarihi Yerleri: Dolmabah&ccedil;e Sarayı, Topkapı Sarayı, Resim ve Heykel
M&uuml;zesi, G&uuml;zel Sanatlar Galerisi, Deniz M&uuml;zesi, Askeri M&uuml;ze, Ayasofya, Yerebatan
Sarayı, Su kemerleri, Anadolu ve Rumeli Hisarları, Galata Kulesi, Sultanahmet Camii,
S&uuml;leymaniye Camii, Boğazi&ccedil;i ve Fatih Sultan Mehmet K&ouml;pr&uuml;leri<br />
<strong>Doğu Anadolu B&ouml;lgesi:</strong><br />
Dağları: Mercan, Nemrut, S&uuml;phan, Buzul, Ağrı, Aladağ, Tend&uuml;rek<br />
Ovaları: Y&uuml;ksekova<br />
G&ouml;lleri: Van g&ouml;l&uuml;,<br />
Akarsuları: Fırat, Dicle, Aras, B&uuml;y&uuml;k Zap, Kura Ceyhan<br />
Tarım &Uuml;r&uuml;nleri: buğday, arpa, yulaf, baklagiller, şeker pancarı, t&uuml;t&uuml;n, pamuk
&ccedil;eşitleri,<br />
Yeraltı Zenginlikleri: demir, bakır, kurşun, &ccedil;inko, g&uuml;m&uuml;ş, krom, linyit<br />
<strong>Ege B&ouml;lgesi:</strong><br />
Dağları: Aydın Dağları, Bozdağlar, Dumlu Dağı, Yunt Dağı, Madra Dağı, Kaz Dağı,
Eğrig&ouml;z Dağı, T&uuml;rkmen Dağı, Şaphane Dağı, Sandıklı Dağları<br />
Ovaları: B&uuml;y&uuml;k ve K&uuml;&ccedil;&uuml;k Menderes Ovaları, Gediz Ovası ve Bakır&ccedil;ay Ovası<br />
K&ouml;rfezleri: Edremit, &Ccedil;andarlı, İzmir, Kuşadası, G&uuml;ll&uuml;k, G&ouml;kova<br />
Akarsuları: B&uuml;y&uuml;k ve K&uuml;&ccedil;&uuml;k Menderes, Bakır&ccedil;ay, Simav (Susurluk), Gediz, Porsuk<br />
Barajları: Adıg&uuml;zel, Kemer, Gediz, Demirk&ouml;pr&uuml;<br />
Tarım &Uuml;r&uuml;nleri: &Ccedil;ekirdeksiz &uuml;z&uuml;m, turun&ccedil;gil, mısır, incir, zeytin, haşhaş,
şeker pancarı ve buğday<br />
Yeraltı Zenginlikleri: Linyit, zımpara taşı, cıva, demir, krom<br />
<strong>Akdeniz B&ouml;lgesi:</strong><br />
Dağları: Toros Dağları, Amanos Dağları (Nur Dağları), Tahtalı Dağları, Bey
Dağları, Akdağlar, &Ccedil;i&ccedil;ekbaba Dağları, Sultan Dağları, Geyik Dağları, Bolkar
Dağları, Binboğa Dağları<br />
Ovaları: &Ccedil;ukurova, Silifke, Antalya, Finike, Fethiye, K&ouml;yceğiz, Amik(Hatay),
Sağlık(T&uuml;rkoğlu- Kahramanmaraş), Acıpayam(Denizli), Isparta ve Burdur Ovları,
Elmalı, Kestel, Korkuteli<br />
G&ouml;lleri: Beyşehir, Eğirdir, Burdur, Acıg&ouml;l, Kestel, Avlan, Suğla, Salda ve
S&ouml;ğ&uuml;t<br />
Akarsuları: Dalaman, Koca&ccedil;ay(Eşen &Ccedil;ayı), Derme, Alakır, Aksu, K&ouml;pr&uuml; ve Manavgat
&Ccedil;ayları, G&ouml;ksu Nehri, Tarsus &Ccedil;ayı, Seyhan, Ceyhan ve Asi Nehirleri<br />
Ge&ccedil;itleri: Belen ( İskenderun &ndash; Antakya), G&uuml;lek ( Adana &ndash; Ulukışla &ndash; Ankara),
Sertavul ( Silifke &ndash; Karaman) ve &Ccedil;ubuk ( Antalya &ndash; G&ouml;ller y&ouml;resi)<br />
Tarım &Uuml;r&uuml;nleri: buğday, pamuk, zeytin, turun&ccedil;gil, mısır, yer fıstığı, susam,
anason, baklagiller, g&uuml;l, şeker pancarı, haşhaş, soya fasulyesi, &uuml;z&uuml;m, elma,
erik, muz, &ccedil;ilek<br />
Yeraltı Zenginlikleri: Krom, boksit, demir, linyit,<br />
G&uuml;neydoğu Anadolu B&ouml;lgesi:<br />
Dağları:<br />
Ovaları: Altınbaşak, Suru&ccedil;, Gaziantep, Barak, Adıyaman, Şanlı Urfa, Harran,
Ceylanpınar<br />
G&ouml;lleri: Azaplı, İnekli, G&ouml;lbaşı<br />
Barajları: Devege&ccedil;idi, Dicle, Batman<br />
Tarım &Uuml;r&uuml;nleri: tahıl, baklagil, pamuk, susam, ay&ccedil;i&ccedil;eği, Antep fıstığı, buğday,
kırımızı mercimek, nohut, t&uuml;t&uuml;n, &uuml;z&uuml;m, zeytin<br />
Yeraltı Zenginlikleri: Fosfat, petrol, &ccedil;imento</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal" style="text-align: center;">Online İKM M&uuml;lakatı:<span style="text-decoration: underline;">www.katipler.net/mulakat</span></p>', NULL, NULL, N'~/Style/folder.png', 1, '20140511 19:20:27.590')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (20, NULL, 32, N'Uzaktan Eğitim Ders Örnekleri', 1, N'Bu Ana Sayfa Olsun', NULL, NULL, N'~/Style/ArsivAna.png', 1, '20140511 19:43:44.077')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (21, 20, 32, N'Youtube Embed', 3, NULL, N'//www.youtube.com/embed/bIvU8AsVgUY', NULL, N'~/Style/folder.png', 1, '20140511 19:44:05.017')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (22, 20, 32, N'Dosyadan Seçim', 2, NULL, N'/Dokumanlar/OmerFarukOcakoglu/ödev 3.pdf', NULL, N'~/Style/folder.png', 1, '20140511 19:44:33.790')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (23, 20, 32, N'Dosyadan Seçim 2', 2, NULL, N'/Dokumanlar/OmerFarukOcakoglu/AppBuilder.mp4', NULL, N'~/Style/folder.png', 1, '20140511 19:45:00.460')
GO

INSERT INTO [dbo].[DersIcerikler] ([IcerikId], [IcerikPId], [OgretmenDersId], [IcerikAdi], [IcerikTip], [IcerikText], [IcerikUrl], [DersSira], [IconUrl], [EkleyenId], [KayitTarihi])
VALUES 
  (24, NULL, 32, N'İçerik Context Yazımı', 1, N'<p><em><span style="text-decoration: underline;"><strong style="color: #c00000; font-size: 20px;">ATAT&Uuml;RK İNKILAPLARI (DEVRİMLERİ)</strong></span></em><br />
I-Siyasi alanda yapılan inkıl&acirc;plar:<br />
1- Saltanatın Kaldırılması (1 Kasım 1922)<br />
2- Cumhuriyet&rsquo;in ilanı (29 Ekim 1923)<br />
3- Halifeliğin Kaldırılması (3 Mart 1924)<br />
II-Toplumsal yaşayışın d&uuml;zenlenmesi:<br />
1- Şapka İktisası (giyilmesi) Hakkında Kanun (25 Kasım 1925)<br />
2- Tekke ve Zaviyelerle T&uuml;rbelerin Seddine (kapatılmasına) ve T&uuml;rbedarlıklar
ile Birtakım Unvanların Men ve İlgasına Dair Kanun (30 Kasım 1925)<br />
3- Beynelmilel Saat ve Takvim Hakkındaki Kanunların Kabul&uuml; (26 Aralık 1925). Kabul
edilen bu kanunlarla Hicri ve Rumi Takvim uygulaması kaldırılarak yerine Miladi
Takvim, alaturka saat yerine de milletlerarası saat sistemi uygulaması
benimsenmiştir.<br />
4- &Ouml;l&ccedil;&uuml;ler Kanunu (1 Nisan 1931). Bu kanunla &ouml;l&ccedil;&uuml; birimi olarak medeni
milletlerin kullandıkları metre, kilogram ve litre kabul edilmiştir.<br />
5- Lakap ve Unvanların Kaldırıldığına Dair Kanun (26 Kasım 1934)<br />
6- Bazı Kisvelerin Giyilemeyeceğine Dair Kanun (3 Aralık 1934). Bu kanunla din
adamlarının, hangi dine mensup olurlarsa olsunlar, mabet ve ayinler dışında
ruhani kisve (giysi) taşımaları yasaklanmıştır.<br />
7- Soyadı Kanunu (21 Haziren 1934)<br />
8- Kemal &Ouml;z Adlı Cumhur reisimize Atat&uuml;rk Soyadı Verilmesi Hakkında Kanun (24
Kasım 1934)<br />
9- Kadınların medeni ve siyasi haklara kavuşması:<br />
a- Medeni Kanun&rsquo;la sağlanan haklar<br />
b- Belediye se&ccedil;imlerinde kadınlara se&ccedil;me ve se&ccedil;ilme hakkı tanıyan kanunun
kabul&uuml; (3 Nisan 1930)<br />
c- Anayasa&rsquo;da yapılan değişiklerle kadınlara milletvekili se&ccedil;me ve se&ccedil;ilme
hakkının tanınması (5 Aralık 1934)<br />
III- Hukuk alanında yapılan inkıl&acirc;plar:<br />
1- Şeriye Mahkemelerinin kaldırılması ve Yeni Mahkemeler Teşkilatının Kurulması
Kanunu (8 Nisan 1934)<br />
2- T&uuml;rk Medeni Kanunu (17 Şubat 1926)<br />
Dini hukuk sisteminden ayrılarak laik &ccedil;ağdaş hukuk sisteminin uygulanmasına
başlanmıştır.<br />
IV-Eğitim ve K&uuml;lt&uuml;r alanında yapılan inkıl&acirc;plar:<br />
1- Tevhid-i Tedrisat Kanunu (3 Mart 1924). Bu kanunla T&uuml;rkiye dahilindeki b&uuml;t&uuml;n
bilim ve &ouml;ğretim kurumları Milli Eğitim Bakanlığı&rsquo;na bağlanmıştır.<br />
2- Yeni T&uuml;rk Harflerinin Kabul ve Tatbiki Hakkında Kanun (1 Kasım 1928)<br />
3- T&uuml;rk Tarihi Tetkik Cemiyeti&rsquo;nin Kuruluşu (12 Nisan 1931). Cemiyet daha sonra
T&uuml;rk Tarih Kurumu adını almıştır (3 Ekim 1935). K&uuml;lt&uuml;r alanında yeni bir tarih
g&ouml;r&uuml;n&uuml;ş&uuml;n&uuml; ifade eden kurumun kuruluşuyla &uuml;mmet tarihi anlayışından millet
tarihi anlayışına ge&ccedil;ilmiştir.<br />
4- T&uuml;rk Dili Tetkik Cemiyeti&rsquo;nin kuruluşu (12 Temmuz 1932). Cemiyet daha sonra
T&uuml;rk Dil Kurumu adını almıştır (24 Ağustos 1936). Kurumun amacı, T&uuml;rk dilinin
&ouml;z g&uuml;zelliğini ve zenginliğini meydana &ccedil;ıkarmak, onu d&uuml;nya dilleri arasında
değerine yaraşır y&uuml;ksekliğe eriştirmektir.<br />
5- İstanbul Dar&uuml;lf&uuml;nunu&rsquo;nun kapatılmasına Milli Eğitim Bakanlığı&rsquo;nca yeni bir
&uuml;niversite kurulmasına dair kanun (31 Mayıs 1933). İstanbul &Uuml;niversitesi 18
Kasım 1933 g&uuml;n&uuml; &ouml;ğretime a&ccedil;ılmıştır</p>
<p class="MsoNormal"><strong><span style="text-decoration: underline;">T&uuml;rkiye&rsquo;nin
komşuları &ndash; Başkentleri: </span></strong></p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">&Uuml;lkemizin sınırları itibariyle sekiz komşu &uuml;lkesi
bulunmaktadır. 8333 kmlik sahil uzunluğuna sahip olan &uuml;lkemizde komşu &uuml;lke
olarak en uzun sınırımız Suriye, en kısa sınırımız ise Nahcivan iledir.</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">turkiyenin komsulari T&uuml;rkiyenin Komşuları Hangileridir? T&uuml;rkiyenin
Komşu &Uuml;lkeleri</p>
<p class="MsoNormal">Doğu komşuları</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">G&uuml;rcistan: T&uuml;rkiye ile ekonomik ilişkiler i&ccedil;inde de bulunan
G&uuml;rcistan, T&uuml;rkiye&rsquo;den hem ithalat yapmakta hem de ihracat yapmaktadır.
Başkenti Tiflis&rsquo;tir.</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">Ermenistan: SSCB&rsquo;ye bağlı iken bu birliğin 1991 yılında
dağılmasıyla bağımsızlığını kazanan Ermenistan&rsquo;ın başkenti Erivan&rsquo;dır.
Azerbaycan&rsquo;a ait bir b&ouml;lge olarak kabul edilmiş olan Dağlık Karabağ b&ouml;lgesinin
%20&prime;sini işgal etmesinden dolayı T&uuml;rkiye, bu &uuml;lke ile sınırlarını kapatmıştır.</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">Nahcivan: i&ccedil; işlerinde &ouml;zerk, dış işlerinde ise Azerbaycan&rsquo;a
bağlı bir b&ouml;lge olan &uuml;lkenin başkenti de Nahcıvan&rsquo;dır</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">İran: T&uuml;rkiye&rsquo;nin komşuları arasında, y&uuml;z&ouml;l&ccedil;&uuml;m&uuml; T&uuml;rkiye&rsquo;den
b&uuml;y&uuml;k olan tek &uuml;lke olan İran&rsquo;ın başkenti Tahran.</p>
<p class="MsoNormal">G&uuml;neydoğu komşusu</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">Irak: petrol zenginliği ve tarıma elverişliliği nedeniyle
olduk&ccedil;a jeopolitik bir &ouml;neme sahip olan Irak, İran&rsquo;dan sonra y&uuml;z&ouml;l&ccedil;&uuml;m&uuml; en geniş
&uuml;lkedir. Başkenti ise Bağdat&rsquo;tır.</p>
<p class="MsoNormal">G&uuml;ney komşusu</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">Suriye: başkenti Şam</p>
<p class="MsoNormal">Batı komşuları</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">Bulgaristan; başkenti Sofya</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal">Yunanistan; başkenti Atina</p>
<p class="MsoNormal">&nbsp;</p>
<p class="MsoNormal"><strong><span style="text-decoration: underline;">COĞRAFYA</span></strong><br />
<strong>İ&ccedil; Anadolu B&ouml;lgesi:</strong><br />
Dağları: Karacadağ, Melendiz, Hasandağı, Erciyes, Tahtalı, Tecer, Yıldız, Ak
Dağları, Sundiken ve Sivrihisar Dağları<br />
Platoları: Haymana, Cihanbeyli, Obruk<br />
G&ouml;lleri: Tuz, Eber, Akşehir, &Ccedil;avuş&ccedil;u, Seyfe, Sultan sazlığı, Tuzla ve Acıg&ouml;l<br />
Akarsuları: Kızılırmak, Delice &Ccedil;ayı, &Ccedil;ekerek Suyu, Ankara &Ccedil;ayı, Porsuk &Ccedil;ayı<br />
Tarım &Uuml;r&uuml;nleri: buğday, arpa, yulaf, şeker pancarı, baklagiller, patates, elma<br />
Yeraltı Zenginlikleri: florid , krom, linyit, bakır, &ccedil;inko, kurşun, manganez,
jips, mika, l&uuml;letaşı<br />
<strong>Karadeniz B&ouml;lgesi:</strong><br />
Dağları: Ilgaz, Canik, Bolu, K&ouml;roğlu, Yalnız&ccedil;am, &Ccedil;imen, Mescit, K&uuml;re, Bolu ve
Doğu Karadeniz Dağları<br />
Ovaları: &Ccedil;arşamba, Bafra<br />
G&ouml;lleri: Tortum, Abant Yedi G&ouml;ller, Borabay, Sera<br />
Tarım &Uuml;r&uuml;nleri: Fındık, &ccedil;ay, mısır, t&uuml;t&uuml;n, şeker pancarı, keten, kenevir, fasulye,
pirin&ccedil;, buğday, &ccedil;eltik<br />
Yeraltı Zenginlikleri: bakır, maden k&ouml;m&uuml;r&uuml;, linyit<br />
<strong>Marmara B&ouml;lgesi:</strong><br />
Dağları: Yıldız, Koru, Biga, Kaz, Kapı, Işıklar, Uludağ<br />
Tarım &Uuml;r&uuml;nleri: ay&ccedil;i&ccedil;eği, buğday, t&uuml;t&uuml;n, şeker pancarı, pamuk, mısır, fındık,
zeytin, pirin&ccedil; patates,<br />
Yeraltı Zenginlikleri:<br />
&Ouml;nemli Tarihi Yerleri: Dolmabah&ccedil;e Sarayı, Topkapı Sarayı, Resim ve Heykel
M&uuml;zesi, G&uuml;zel Sanatlar Galerisi, Deniz M&uuml;zesi, Askeri M&uuml;ze, Ayasofya, Yerebatan
Sarayı, Su kemerleri, Anadolu ve Rumeli Hisarları, Galata Kulesi, Sultanahmet Camii,
S&uuml;leymaniye Camii, Boğazi&ccedil;i ve Fatih Sultan Mehmet K&ouml;pr&uuml;leri<br />
<strong>Doğu Anadolu B&ouml;lgesi:</strong><br />
Dağları: Mercan, Nemrut, S&uuml;phan, Buzul, Ağrı, Aladağ, Tend&uuml;rek<br />
Ovaları: Y&uuml;ksekova<br />
G&ouml;lleri: Van g&ouml;l&uuml;,<br />
Akarsuları: Fırat, Dicle, Aras, B&uuml;y&uuml;k Zap, Kura Ceyhan<br />
Tarım &Uuml;r&uuml;nleri: buğday, arpa, yulaf, baklagiller, şeker pancarı, t&uuml;t&uuml;n, pamuk
&ccedil;eşitleri,<br />
Yeraltı Zenginlikleri: demir, bakır, kurşun, &ccedil;inko, g&uuml;m&uuml;ş, krom, linyit<br />
<strong>Ege B&ouml;lgesi:</strong><br />
Dağları: Aydın Dağları, Bozdağlar, Dumlu Dağı, Yunt Dağı, Madra Dağı, Kaz Dağı,
Eğrig&ouml;z Dağı, T&uuml;rkmen Dağı, Şaphane Dağı, Sandıklı Dağları<br />
Ovaları: B&uuml;y&uuml;k ve K&uuml;&ccedil;&uuml;k Menderes Ovaları, Gediz Ovası ve Bakır&ccedil;ay Ovası<br />
K&ouml;rfezleri: Edremit, &Ccedil;andarlı, İzmir, Kuşadası, G&uuml;ll&uuml;k, G&ouml;kova<br />
Akarsuları: B&uuml;y&uuml;k ve K&uuml;&ccedil;&uuml;k Menderes, Bakır&ccedil;ay, Simav (Susurluk), Gediz, Porsuk<br />
Barajları: Adıg&uuml;zel, Kemer, Gediz, Demirk&ouml;pr&uuml;<br />
Tarım &Uuml;r&uuml;nleri: &Ccedil;ekirdeksiz &uuml;z&uuml;m, turun&ccedil;gil, mısır, incir, zeytin, haşhaş,
şeker pancarı ve buğday<br />
Yeraltı Zenginlikleri: Linyit, zımpara taşı, cıva, demir, krom<br />
<strong>Akdeniz B&ouml;lgesi:</strong><br />
Dağları: Toros Dağları, Amanos Dağları (Nur Dağları), Tahtalı Dağları, Bey
Dağları, Akdağlar, &Ccedil;i&ccedil;ekbaba Dağları, Sultan Dağları, Geyik Dağları, Bolkar
Dağları, Binboğa Dağları<br />
Ovaları: &Ccedil;ukurova, Silifke, Antalya, Finike, Fethiye, K&ouml;yceğiz, Amik(Hatay),
Sağlık(T&uuml;rkoğlu- Kahramanmaraş), Acıpayam(Denizli), Isparta ve Burdur Ovları,
Elmalı, Kestel, Korkuteli<br />
G&ouml;lleri: Beyşehir, Eğirdir, Burdur, Acıg&ouml;l, Kestel, Avlan, Suğla, Salda ve
S&ouml;ğ&uuml;t<br />
Akarsuları: Dalaman, Koca&ccedil;ay(Eşen &Ccedil;ayı), Derme, Alakır, Aksu, K&ouml;pr&uuml; ve Manavgat
&Ccedil;ayları, G&ouml;ksu Nehri, Tarsus &Ccedil;ayı, Seyhan, Ceyhan ve Asi Nehirleri<br />
Ge&ccedil;itleri: Belen ( İskenderun &ndash; Antakya), G&uuml;lek ( Adana &ndash; Ulukışla &ndash; Ankara),
Sertavul ( Silifke &ndash; Karaman) ve &Ccedil;ubuk ( Antalya &ndash; G&ouml;ller y&ouml;resi)<br />
Tarım &Uuml;r&uuml;nleri: buğday, pamuk, zeytin, turun&ccedil;gil, mısır, yer fıstığı, susam,
anason, baklagiller, g&uuml;l, şeker pancarı, haşhaş, soya fasulyesi, &uuml;z&uuml;m, elma,
erik, muz, &ccedil;ilek<br />
Yeraltı Zenginlikleri: Krom, boksit, demir, linyit,<br />
G&uuml;neydoğu Anadolu B&ouml;lgesi:<br />
Dağları:<br />
Ovaları: Altınbaşak, Suru&ccedil;, Gaziantep, Barak, Adıyaman, Şanlı Urfa, Harran,
Ceylanpınar<br />
G&ouml;lleri: Azaplı, İnekli, G&ouml;lbaşı<br />
Barajları: Devege&ccedil;idi, Dicle, Batman<br />
Tarım &Uuml;r&uuml;nleri: tahıl, baklagil, pamuk, susam, ay&ccedil;i&ccedil;eği, Antep fıstığı, buğday,
kırımızı mercimek, nohut, t&uuml;t&uuml;n, &uuml;z&uuml;m, zeytin<br />
Yeraltı Zenginlikleri: Fosfat, petrol, &ccedil;imento</p>
<p>&nbsp;</p>', NULL, NULL, N'~/Style/ArsivAna.png', 1, '20140511 19:46:49.250')
GO

SET IDENTITY_INSERT [dbo].[DersIcerikler] OFF
GO

--
-- Data for table dbo.Dersler  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[Dersler] ON
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (2, N'Fizik1', N'...', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (3, N'Yeni Ders', N'Yeni Ders Açıklama', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (4, N'Biyoloji', N'Açıklama...', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (5, N'Sayısal Analiz', N'Sayısal Analiz', 1)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (6, N'Akışkanlar Mekaniği', N'Akışkanlar Mekaniği', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (7, N'Termodinamik II', N'Termodinamik II', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (8, N'Dinamik', N'Dinamik ders', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (9, N'Mukavemet II', N'Mukavemet II', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (10, N'İmal Usülleri', N'İmal Usülleri', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (11, N'Isı Geçişi', N'Isı Geçişi', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (12, N'Makine Elemanları II', N'Makine Elemanları II', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (13, N'Sistem Dinamiği ve Kontrolü', N'Sistem Dinamiği ve Kontrolü', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (14, N'Makine Dinamiği', N'Makine Dinamiği', 1)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (15, N'Diferansiyel Denklemler', N'Diferansiyel Denklemler', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (16, N'Mekanizma Tekniği', N'Mekanizma Tekniği', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (17, N'VERİ YAPILARI', N'VERİ YAPILARI', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (18, N'AYRIK İŞLEMSEL YAPILAR', N'AYRIK İŞLEMSEL YAPILAR', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (19, N'MANTIK DEVRELERİ', N'MANTIK DEVRELERİ', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (20, N'BİLGİSAYAR ORGANİZASYONU', N'BİLGİSAYAR ORGANİZASYONU', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (21, N'NESNEYE DAYALI PROGRAMLAMA', N'NESNEYE DAYALI PROGRAMLAMA', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (22, N'BİÇİMSEL DİLLER VE SOYUT MAKİNELER', N'BİÇİMSEL DİLLER VE SOYUT MAKİNELER', 1)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (23, N'VERİ TABANI YÖNETİM SİSTEMLERİ', N'VERİ TABANI YÖNETİM SİSTEMLERİ', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (24, N'İŞARETLER VE SİSTEMLER', N'İŞARETLER VE SİSTEMLER', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (25, N'Matematik', N'Temel Matematik Dersleri', 1)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (26, N'SİSTEM PROGRAMLAMA', N'SİSTEM PROGRAMLAMA', 1)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (27, N'YAZILIM MÜHENDİSLİĞİ', N'YAZILIM MÜHENDİSLİĞİ', 1)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (28, N'BİLGİSAYAR AĞLARI(YENİ)', N'BİLGİSAYAR AĞLARI', 1)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (29, N'Kamu Yonetim', N'Kamu Yonetim Acıklama', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (30, N'DENEME1 DERSİ', N'TEST1', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (31, N'DENEME2 DERSİ', N'TEST2', 0)
GO

INSERT INTO [dbo].[Dersler] ([DersId], [DersAdi], [DersAciklama], [DersDurum])
VALUES 
  (32, N'Uzaktan Eğitim', N'Uzaktan Eğitim Açıklama', 1)
GO

SET IDENTITY_INSERT [dbo].[Dersler] OFF
GO

--
-- Data for table dbo.DuyuruKullanicilar  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[DuyuruKullanicilar] ON
GO

INSERT INTO [dbo].[DuyuruKullanicilar] ([Id], [DuyuruId], [KullaniciTipiId])
VALUES 
  (25, 2, 1)
GO

INSERT INTO [dbo].[DuyuruKullanicilar] ([Id], [DuyuruId], [KullaniciTipiId])
VALUES 
  (26, 2, 2)
GO

INSERT INTO [dbo].[DuyuruKullanicilar] ([Id], [DuyuruId], [KullaniciTipiId])
VALUES 
  (27, 2, 8)
GO

INSERT INTO [dbo].[DuyuruKullanicilar] ([Id], [DuyuruId], [KullaniciTipiId])
VALUES 
  (28, 2, 12)
GO

INSERT INTO [dbo].[DuyuruKullanicilar] ([Id], [DuyuruId], [KullaniciTipiId])
VALUES 
  (72, 10, 1)
GO

INSERT INTO [dbo].[DuyuruKullanicilar] ([Id], [DuyuruId], [KullaniciTipiId])
VALUES 
  (74, 11, 14)
GO

SET IDENTITY_INSERT [dbo].[DuyuruKullanicilar] OFF
GO

--
-- Data for table dbo.Duyurular  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[Duyurular] ON
GO

INSERT INTO [dbo].[Duyurular] ([DuyuruId], [DuyuruAdi], [DuyuruIcerik], [DuyuruTarihi], [DuyuruKayitEdenId])
VALUES 
  (1, N'test', N'test', '20140426', NULL)
GO

INSERT INTO [dbo].[Duyurular] ([DuyuruId], [DuyuruAdi], [DuyuruIcerik], [DuyuruTarihi], [DuyuruKayitEdenId])
VALUES 
  (2, N'Duyuru Adı', N'Sayın Kullanıcılar 07.04.2014 – 11.04.2014 tarihleri arasında Rıfat Börekçi Eğitim Merkezi Müdürlüğünde yapılan “Kurum İçi Naklen İmam-Hatip ve Müezzin-Kayyım Alımı Sözlü Sınavı” sonucunda başarılı olarak atama kontenjanına giren adaylardan sözlü sınav puanına göre 113 imam-hatibin tercihlerine göre yerleştirmeleri yapılmıştır. Adaylar, yerleştirme sonuçlarını https://ikys.diyanet.gov.tr internet adresinden öğrenebilirler.   İlgililere duyurulur.', '20140426', 1)
GO

INSERT INTO [dbo].[Duyurular] ([DuyuruId], [DuyuruAdi], [DuyuruIcerik], [DuyuruTarihi], [DuyuruKayitEdenId])
VALUES 
  (3, N'Duyuru Adı', N'test mest', '20140426 22:08:18.013', 1)
GO

INSERT INTO [dbo].[Duyurular] ([DuyuruId], [DuyuruAdi], [DuyuruIcerik], [DuyuruTarihi], [DuyuruKayitEdenId])
VALUES 
  (10, N'Çalışmaya Devam', N'Daha özenli ve tertipli çalışmak lazım velhasıl aynen Devam', '20140504', 1)
GO

INSERT INTO [dbo].[Duyurular] ([DuyuruId], [DuyuruAdi], [DuyuruIcerik], [DuyuruTarihi], [DuyuruKayitEdenId])
VALUES 
  (11, N'Sayın Meslektaşlarım', N'Hepinizin bildiği üzere uzaktan eğitim projesi kapsamında eklediğiniz içerikleri özenle ve dikkatle yapacağına inanıyorum. Test çalışması kapsamında verdiğiniz destekten dolayı hepinize çok teşekkür ederim. 

  Hepinize çalışmalarında başarılar dilerim', '20140508', 1)
GO

SET IDENTITY_INSERT [dbo].[Duyurular] OFF
GO

--
-- Data for table dbo.EFormlar  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[EFormlar] ON
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (1, NULL, N'Kullanıcı Işlemleri', N'Kullanıcı Işlemleri', N'', N'Kullanıcı Işlemleri Formu Açıklaması', N'UserHome')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (2, 1, N'Kullanıcı Işlemleri', N'Kullanici Listesi', N'~/Pages/KullaniciIslemleri/KullaniciListesi.aspx', N'Kullanici Listesi Formu Açıklaması', N'User')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (3, 1, N'Kullanıcı Işlemleri', N'Kullanici Tipleri', N'~/Pages/KullaniciTurleri.aspx', N'Kullanici Tipleri Formu Açıklaması', N'UserGo')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (4, 1, N'Kullanıcı Işlemleri', N'Kullanici Yetkileri', N'~/Pages/KullaniciIslemleri/KullaniciYetkileri.aspx', N'Kullanici Yetkileri Formu Açıklaması', N'UserTick')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (5, NULL, N'Ders Duzenleme', N'Ders Duzenleme', NULL, N'', N'Folder')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (6, 5, N'Ders Duzenleme', N'Ders Ekleme', N'~/Pages/Dersler.aspx', N'', N'FolderAdd')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (7, NULL, N'Ders İşlemleri', N'Ders İşlemleri', NULL, N'', N'ChartOrganisation')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (8, 7, N'Ders İşlemleri', N'Internet Dersi', NULL, NULL, N'BookTabs')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (9, 8, N'Ders İşlemleri', N'Ders - 1', N'https://skydrive.live.com/embed?cid=7F017282B77270C5&resid=7F017282B77270C5%21262&authkey=&em=2&wdAr=1.3333333333333333', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (10, 8, N'Ders İşlemleri', N'Ders - 2', N'http://www.youtube.com/embed/-GdUN6-4GCs', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (11, 8, N'Ders İşlemleri', N'Ders - 3', N'https://skydrive.live.com/embed?cid=7F017282B77270C5&resid=7F017282B77270C5%21231&authkey=&em=2&wdStartOn=1', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (12, 7, N'Ders İşlemleri', N'Arttırılmış Gerçeklik', NULL, NULL, N'BookTabs')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (13, 12, N'Ders İşlemleri', N'Konu Dağılımı', N'https://skydrive.live.com/embed?cid=7674BE254E076E5F&resid=7674BE254E076E5F%21120&authkey=&em=2&wdAllowInteractivity=False&Item=''Sayfa1''!A1%3AE8"', N'Konu Dağılımı', N'Bookmark')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (14, 12, N'Ders İşlemleri', N'Vize Final Yönerge', N'https://skydrive.live.com/embed?cid=7674BE254E076E5F&resid=7674BE254E076E5F%21119&authkey=&em=2&wdStartOn=1', N'', N'Bookmark')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (15, 12, N'Ders İşlemleri', N'A Survey of Augmented Reality', N'~/Dokuman/a1.pdf', N'', N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (16, 12, N'Ders İşlemleri', N'AR and education_ Current projects and the potential for classroom learning', N'~/Dokuman/a2.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (17, 12, N'Ders İşlemleri', N'Ar in education', N'~/Dokuman/a3.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (18, 12, N'Ders İşlemleri', N'Ar simulations on pda', N'~/Dokuman/a4.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (19, 12, N'Ders İşlemleri', N'Evaluation of AR book', N'~/Dokuman/a5.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (20, 12, N'Ders İşlemleri', N'Experiences with AR', N'~/Dokuman/a6.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (21, 12, N'Ders İşlemleri', N'Making it real_exploring the potential of AR for teaching primary school science', N'~/Dokuman/a7.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (22, 12, N'Ders İşlemleri', N'The Future of Learning and Training in Augmented Reality', N'~/Dokuman/a8.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (23, 12, N'Ders İşlemleri', N'Ortak-Herkes Okuyacak', NULL, N'', N'BookTabs')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (24, 23, N'Ders İşlemleri', N'Ar_An overview and five directions for AR in education', N'~/Dokuman/Ortak/a1.pdf', NULL, N'BookRed')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (25, 23, N'Ders İşlemleri', N'Augmented reality in education and training', N'~/Dokuman/Ortak/a2.pdf', NULL, N'BookRed')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (26, 23, N'Ders İşlemleri', N'Augmented Reality in Education Current Technologies and the Potential for Education', N'~/Dokuman/Ortak/a3.pdf', NULL, N'BookRed')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (1, NULL, N'Kullanıcı Işlemleri', N'Kullanıcı Işlemleri', N'', N'Kullanıcı Işlemleri Formu Açıklaması', N'UserHome')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (2, 1, N'Kullanıcı Işlemleri', N'Kullanici Listesi', N'~/Pages/KullaniciIslemleri/KullaniciListesi.aspx', N'Kullanici Listesi Formu Açıklaması', N'User')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (3, 1, N'Kullanıcı Işlemleri', N'Kullanici Tipleri', N'~/Pages/KullaniciTurleri.aspx', N'Kullanici Tipleri Formu Açıklaması', N'UserGo')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (4, 1, N'Kullanıcı Işlemleri', N'Kullanici Yetkileri', N'~/Pages/KullaniciIslemleri/KullaniciYetkileri.aspx', N'Kullanici Yetkileri Formu Açıklaması', N'UserTick')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (5, NULL, N'Ders Duzenleme', N'Ders Duzenleme', NULL, N'', N'Folder')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (6, 5, N'Ders Duzenleme', N'Ders Ekleme', N'~/Pages/Dersler.aspx', N'', N'FolderAdd')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (7, NULL, N'Ders İşlemleri', N'Ders İşlemleri', NULL, N'', N'ChartOrganisation')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (8, 7, N'Ders İşlemleri', N'Internet Dersi', NULL, NULL, N'BookTabs')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (9, 8, N'Ders İşlemleri', N'Ders - 1', N'https://skydrive.live.com/embed?cid=7F017282B77270C5&resid=7F017282B77270C5%21262&authkey=&em=2&wdAr=1.3333333333333333', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (10, 8, N'Ders İşlemleri', N'Ders - 2', N'http://www.youtube.com/embed/-GdUN6-4GCs', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (11, 8, N'Ders İşlemleri', N'Ders - 3', N'https://skydrive.live.com/embed?cid=7F017282B77270C5&resid=7F017282B77270C5%21231&authkey=&em=2&wdStartOn=1', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (12, 7, N'Ders İşlemleri', N'Arttırılmış Gerçeklik', NULL, NULL, N'BookTabs')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (14, 12, N'Ders İşlemleri', N'Vize Final Yönerge', N'https://skydrive.live.com/embed?cid=7674BE254E076E5F&resid=7674BE254E076E5F%21119&authkey=&em=2&wdStartOn=1', N'', N'Bookmark')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (13, 12, N'Ders İşlemleri', N'Konu Dağılımı', N'https://skydrive.live.com/embed?cid=7674BE254E076E5F&resid=7674BE254E076E5F%21120&authkey=&em=2&wdAllowInteractivity=False&Item=''Sayfa1''!A1%3AE8"', N'Konu Dağılımı', N'Bookmark')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (15, 12, N'Ders İşlemleri', N'A Survey of Augmented Reality', N'~/Dokuman/a1.pdf', N'', N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (16, 12, N'Ders İşlemleri', N'AR and education_ Current projects and the potential for classroom learning', N'~/Dokuman/a2.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (17, 12, N'Ders İşlemleri', N'Ar in education', N'~/Dokuman/a3.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (18, 12, N'Ders İşlemleri', N'Ar simulations on pda', N'~/Dokuman/a4.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (19, 12, N'Ders İşlemleri', N'Evaluation of AR book', N'~/Dokuman/a5.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (20, 12, N'Ders İşlemleri', N'Experiences with AR', N'~/Dokuman/a6.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (21, 12, N'Ders İşlemleri', N'Making it real_exploring the potential of AR for teaching primary school science', N'~/Dokuman/a7.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (22, 12, N'Ders İşlemleri', N'The Future of Learning and Training in Augmented Reality', N'~/Dokuman/a8.pdf', NULL, N'Book')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (23, 12, N'Ders İşlemleri', N'Ortak-Herkes Okuyacak', NULL, N'', N'BookTabs')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (24, 23, N'Ders İşlemleri', N'Ar_An overview and five directions for AR in education', N'~/Dokuman/Ortak/a1.pdf', NULL, N'BookRed')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (25, 23, N'Ders İşlemleri', N'Augmented reality in education and training', N'~/Dokuman/Ortak/a2.pdf', NULL, N'BookRed')
GO

INSERT INTO [dbo].[EFormlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormIcon])
VALUES 
  (26, 23, N'Ders İşlemleri', N'Augmented Reality in Education Current Technologies and the Potential for Education', N'~/Dokuman/Ortak/a3.pdf', NULL, N'BookRed')
GO

SET IDENTITY_INSERT [dbo].[EFormlar] OFF
GO

--
-- Data for table dbo.Formlar  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[Formlar] ON
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (1, NULL, NULL, N'Kullanıcı Işlemleri', NULL, NULL, N'~/Style/FormIcons/users_family.png')
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (2, 1, NULL, N'Kullanici Listesi', N'~/Forms/KullaniciListesi.aspx', NULL, N'~/Style/FormIcons/P.List.png')
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (3, 1, NULL, N'Kullanici Tipleri', N'~/Forms/KullaniciTipleri.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (4, 1, NULL, N'Kullanici Yetkileri', N'~/Forms/KullaniciTipiYetkiler.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (5, NULL, NULL, N'Duyuru İşlemleri', NULL, NULL, N'~/Style/FormIcons/note.png')
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (6, 5, NULL, N'Yeni Duyuru Ekle', N'~/Forms/DuyuruDetay.aspx', NULL, N'~/Style/FormIcons/Yeni_Duyuru_Ekle.png')
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (7, 5, NULL, N'Yayınlanan Duyurular', N'~/Forms/DuyuruListe.aspx', NULL, N'~/Style/FormIcons/Yayınlanan_Duyurular.png')
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (8, 5, NULL, N'Duyuru Önizleme', N'~/Forms/DefaultDuyuru.aspx', NULL, N'~/Style/FormIcons/Duyuru_Onizleme.png')
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (9, NULL, NULL, N'Ders İşlemleri(Öğrenci)', NULL, NULL, N'~/Style/FormIcons/book_yellow.png')
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (10, 9, NULL, N'Ders Seçimi', N'~/Forms/OgrenciDersSecim.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (11, 9, NULL, N'Derslerim', N'~/Forms/OgrenciDersleri.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (12, 9, NULL, N'Ders Konularım', N'~/Forms/OgrenciDersKonular.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (13, NULL, NULL, N'Ders İşlemleri(Öğretmen)', NULL, NULL, N'~/Style/FormIcons/book_green.png')
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (14, 13, NULL, N'Ders Seçimi', N'~/Forms/OgretmenDersSecim.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (15, 13, NULL, N'Derslerim', N'~/Forms/OgretmenDersleri.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (16, NULL, NULL, N'İdari Onay Ekranları', N'', NULL, N'~/Style/FormIcons/check2.png')
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (17, 16, NULL, N'Ders Tanımlama', N'~/Forms/Dersler.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (18, 16, NULL, N'Öğretmen Ders Onayla', N'~/Forms/OgretmenDersOnay.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (19, 16, NULL, N'Öğrenci Ders Onayla', N'~/Forms/OgrenciDersOnay.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (24, 16, NULL, N'Açılmış Dersler', N'~/Forms/AcilmisDersler.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (25, 13, NULL, N'Dosya Yönetici', N'~/Forms/DosyaYoneticisi.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (26, 13, NULL, N'Ders İçerik Yöneticisi', N'~/Forms/DersIcerikYoneticisi.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (27, 9, NULL, N'Sınav', N'~/Forms/Sinav.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (28, NULL, NULL, N'Sınav İşlemleri(Öğretmen)', NULL, NULL, N'~/Style/FormIcons/book_green.png')
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (29, 28, NULL, N'Soru Ekle', N'~/Forms/SoruDetay.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (30, 28, NULL, N'Soru Bankası', N'~/Forms/SoruBankasi.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (31, 28, NULL, N'Sinav Listesi', N'~/Forms/SinavListesi.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (32, NULL, NULL, N'Ayarlar', NULL, NULL, N'~/Style/FormIcons/wrench.png')
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (33, 32, NULL, N'Kullanici Bilgilerim', N'~/Forms/KullaniciBilgisi.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (34, 32, NULL, N'Tercihlerim', N'~/Forms/Tercihler.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (35, 32, NULL, N'Diğer Ayarlar', NULL, NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (36, NULL, NULL, N'Sınav İşlemleri(Öğrenci)', NULL, NULL, N'~/Style/FormIcons/book_green.png')
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (37, 36, NULL, N'Bekleyen Sınavlarım', N'~/Forms/OgrenciSinavListesi.aspx', NULL, NULL)
GO

INSERT INTO [dbo].[Formlar] ([Id], [PId], [PFormBaslik], [FormBaslik], [FormAdi], [FormAciklama], [FormImageUrl])
VALUES 
  (38, 36, NULL, N'Geçmiş Sınavlar', N'~/Forms/OgrenciGecmisSinavlar.aspx', NULL, NULL)
GO

SET IDENTITY_INSERT [dbo].[Formlar] OFF
GO

--
-- Data for table dbo.Il  (LIMIT 0,500)
--

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (1, N'Adana')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (2, N'Adıyaman')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (3, N'Afyonkarahisar')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (4, N'Ağrı')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (5, N'Amasya')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (6, N'Ankara')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (7, N'Antalya')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (8, N'Artvin')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (9, N'Aydın')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (10, N'Balıkesir')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (11, N'Bilecik')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (12, N'Bingöl')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (13, N'Bitlis')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (14, N'Bolu')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (15, N'Burdur')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (16, N'Bursa')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (17, N'Çanakkale')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (18, N'Çankırı')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (19, N'Çorum')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (20, N'Denizli')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (21, N'Diyarbakır')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (22, N'Edirne')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (23, N'Elazığ')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (24, N'Erzincan')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (25, N'Erzurum')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (26, N'Eskişehir')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (27, N'Gaziantep')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (28, N'Giresun')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (29, N'Gümüşhane')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (30, N'Hakkari')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (31, N'Hatay')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (32, N'Isparta')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (33, N'Mersin')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (34, N'İstanbul')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (35, N'İzmir')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (36, N'Kars')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (37, N'Kastamonu')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (38, N'Kayseri')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (39, N'Kırklareli')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (40, N'Kırşehir')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (41, N'Kocaeli')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (42, N'Konya')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (43, N'Kütahya')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (44, N'Malatya')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (45, N'Manisa')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (46, N'Kahramanmaraş')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (47, N'Mardin')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (48, N'Muğla')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (49, N'Muş')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (50, N'Nevşehir')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (51, N'Niğde')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (52, N'Ordu')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (53, N'Rize')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (54, N'Sakarya')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (55, N'Samsun')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (56, N'Siirt')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (57, N'Sinop')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (58, N'Sivas')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (59, N'Tekirdağ')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (60, N'Tokat')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (61, N'Trabzon')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (62, N'Tunceli')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (63, N'Şanlıurfa')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (64, N'Uşak')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (65, N'Van')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (66, N'Yozgat')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (67, N'Zonguldak')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (68, N'Aksaray')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (69, N'Bayburt')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (70, N'Karaman')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (71, N'Kırıkkale')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (72, N'Batman')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (73, N'Şırnak')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (74, N'Bartın')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (75, N'Ardahan')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (76, N'Iğdır')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (77, N'Yalova')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (78, N'Karabük')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (79, N'Kilis')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (80, N'Osmaniye')
GO

INSERT INTO [dbo].[Il] ([IlKodu], [IlAdi])
VALUES 
  (81, N'Düzce')
GO

--
-- Data for table dbo.Ilce  (LIMIT 0,500)
--

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1101, N'Abana', 37, N'Kastamonu', N'TR8213701000000', N'abana')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1102, N'Acıpayam', 20, N'Denizli', N'TR3222001000000', N'acıpayam')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1103, N'Adalar', 34, N'İstanbul', N'TR1003401000000', N'adalar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1104, N'Seyhan', 1, N'Adana', N'TR6210101000000', N'seyhan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1105, N'Adıyaman Merkez', 2, N'Adıyaman', N'TRC120200000000', N'adıyaman')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1106, N'Adilcevaz', 13, N'Bitlis', N'TRB231301000000', N'adilcevaz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1107, N'Afşin', 46, N'Kahramanmaraş', N'TR6324601000000', N'afşin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1108, N'Afyonkarahisar Merkez', 3, N'Afyonkarahisar', N'TR3320300000000', N'afyonkarahisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1109, N'Ağlasun', 15, N'Burdur', N'TR6131501000000', N'ağlasun')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1110, N'Ağın', 23, N'Elazığ', N'TRB122301000000', N'ağın')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1111, N'Ağrı Merkez', 4, N'Ağrı', N'TRA210400000000', N'ağrı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1112, N'Ahlat', 13, N'Bitlis', N'TRB231302000000', N'ahlat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1113, N'Akçaabat', 61, N'Trabzon', N'TR9016101000000', N'akçaabat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1114, N'Akçadağ', 44, N'Malatya', N'TRB114401000000', N'akçadağ')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1115, N'Akçakale', 63, N'Şanlıurfa', N'TRC216301000000', N'akçakale')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1116, N'Akçakoca', 81, N'Düzce', N'TR4238101000000', N'akçakoca')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1117, N'Akdağmadeni', 66, N'Yozgat', N'TR7236601000000', N'akdağmadeni')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1118, N'Akhisar', 45, N'Manisa', N'TR3314502000000', N'akhisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1119, N'Akkuş', 52, N'Ordu', N'TR9025201000000', N'akkuş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1120, N'Aksaray Merkez', 68, N'Aksaray', N'TR7126800000000', N'aksaray')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1121, N'Akseki', 7, N'Antalya', N'TR6110701000000', N'akseki')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1122, N'Akşehir', 42, N'Konya', N'TR5214206000000', N'akşehir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1123, N'Akyazı', 54, N'Sakarya', N'TR4225403000000', N'akyazı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1124, N'Alaca', 19, N'Çorum', N'TR8331901000000', N'alaca')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1125, N'Alaçam', 55, N'Samsun', N'TR8315501000000', N'alaçam')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1126, N'Alanya', 7, N'Antalya', N'TR6110702000000', N'alanya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1127, N'Alaşehir', 45, N'Manisa', N'TR3314503000000', N'alaşehir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1128, N'Aliağa', 35, N'İzmir', N'TR3103510000000', N'aliağa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1129, N'Almus', 60, N'Tokat', N'TR8326001000000', N'almus')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1130, N'Altındağ', 6, N'Ankara', N'TR5100601000000', N'altındağ')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1131, N'Altınözü', 31, N'Hatay', N'TR6313101000000', N'altınözü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1132, N'Altıntaş', 43, N'Kütahya', N'TR3334301000000', N'altıntaş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1133, N'Alucra', 28, N'Giresun', N'TR9032801000000', N'alucra')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1134, N'Amasya Merkez', 5, N'Amasya', N'TR8340500000000', N'amasya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1135, N'Anamur', 33, N'Mersin', N'TR6223301000000', N'anamur')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1136, N'Andırın', 46, N'Kahramanmaraş', N'TR6324602000000', N'andırın')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1137, N'Ankara', 6, N'Ankara', NULL, N'ankara')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1138, N'Antalya Merkez', 7, N'Antalya', N'TR6110700000000', N'antalya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1139, N'Araban', 27, N'Gaziantep', N'TRC112703000000', N'araban')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1140, N'Araç', 37, N'Kastamonu', N'TR8213703000000', N'araç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1141, N'Araklı', 61, N'Trabzon', N'TR9016102000000', N'araklı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1142, N'Aralık', 76, N'Iğdır', N'TRA237601000000', N'aralık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1143, N'Arapgir', 44, N'Malatya', N'TRB114402000000', N'arapgir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1144, N'Ardahan Merkez', 75, N'Ardahan', N'TRA247500000000', N'ardahan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1145, N'Ardanuç', 8, N'Artvin', N'TR9050801000000', N'ardanuç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1146, N'Ardeşen', 53, N'Rize', N'TR9045301000000', N'ardeşen')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1147, N'Arhavi', 8, N'Artvin', N'TR9050802000000', N'arhavi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1148, N'Arguvan', 44, N'Malatya', N'TRB114403000000', N'arguvan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1149, N'Arpaçay', 36, N'Kars', N'TRA223602000000', N'arpaçay')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1150, N'Arsin', 61, N'Trabzon', N'TR9016103000000', N'arsin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1151, N'Artova', 60, N'Tokat', N'TR8326002000000', N'artova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1152, N'Artvin Merkez', 8, N'Artvin', N'TR9050800000000', N'artvin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1153, N'Aşkale', 25, N'Erzurum', N'TRA112501000000', N'aşkale')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1154, N'Atabey', 32, N'Isparta', N'TR6123202000000', N'atabey')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1155, N'Avanos', 50, N'Nevşehir', N'TR7145002000000', N'avanos')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1156, N'Ayancık', 57, N'Sinop', N'TR8235701000000', N'ayancık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1157, N'Ayaş', 6, N'Ankara', N'TR5100610000000', N'ayaş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1158, N'Aybastı', 52, N'Ordu', N'TR9025202000000', N'aybastı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1159, N'Aydın Merkez', 9, N'Aydın', N'TR3210900000000', N'aydın')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1160, N'Ayvacık / Çanakkale', 17, N'Çanakkale', N'TR2221701000000', N'ayvacık  çanakkale')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1161, N'Ayvalık', 10, N'Balıkesir', N'TR2211001000000', N'ayvalık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1162, N'Azdavay', 37, N'Kastamonu', N'TR8213704000000', N'azdavay')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1163, N'Babaeski', 39, N'Kırklareli', N'TR2133901000000', N'babaeski')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1164, N'Bafra', 55, N'Samsun', N'TR8315504000000', N'bafra')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1165, N'Bahçe', 80, N'Osmaniye', N'TR6338001000000', N'bahçe')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1166, N'Bakırköy', 34, N'İstanbul', N'TR1003405000000', N'bakırköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1167, N'Bala', 6, N'Ankara', N'TR5100611000000', N'bala')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1168, N'Balıkesir Merkez', 10, N'Balıkesir', N'TR2211000000000', N'balıkesir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1169, N'Balya', 10, N'Balıkesir', N'TR2211002000000', N'balya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1170, N'Banaz', 64, N'Uşak', N'TR3346401000000', N'banaz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1171, N'Bandırma', 10, N'Balıkesir', N'TR2211003000000', N'bandırma')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1172, N'Bartın Merkez', 74, N'Bartın', N'TR8137400000000', N'bartın')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1173, N'Baskil', 23, N'Elazığ', N'TRB122304000000', N'baskil')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1174, N'Batman Merkez', 72, N'Batman', N'TRC327200000000', N'batman')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1175, N'Başkale', 65, N'Van', N'TRB216502000000', N'başkale')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1176, N'Bayburt Merkez', 69, N'Bayburt', N'TRA136900000000', N'bayburt')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1177, N'Bayat / Çorum', 19, N'Çorum', N'TR8331902000000', N'bayat  çorum')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1178, N'Bayındır', 35, N'İzmir', N'TR3103511000000', N'bayındır')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1179, N'Baykan', 56, N'Siirt', N'TRC345602000000', N'baykan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1180, N'Bayramiç', 17, N'Çanakkale', N'TR2221702000000', N'bayramiç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1181, N'Bergama', 35, N'İzmir', N'TR3103512000000', N'bergama')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1182, N'Besni', 2, N'Adıyaman', N'TRC120201000000', N'besni')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1183, N'Beşiktaş', 34, N'İstanbul', N'TR1003407000000', N'beşiktaş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1184, N'Beşiri', 72, N'Batman', N'TRC327201000000', N'beşiri')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1185, N'Beykoz', 34, N'İstanbul', N'TR1003408000000', N'beykoz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1186, N'Beyoğlu', 34, N'İstanbul', N'TR1003409000000', N'beyoğlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1187, N'Beypazarı', 6, N'Ankara', N'TR5100612000000', N'beypazarı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1188, N'Beyşehir', 42, N'Konya', N'TR5214208000000', N'beyşehir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1189, N'Beytüşşebap', 73, N'Şırnak', N'TRC337301000000', N'beytüşşebap')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1190, N'Biga', 17, N'Çanakkale', N'TR2221703000000', N'biga')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1191, N'Bigadiç', 10, N'Balıkesir', N'TR2211004000000', N'bigadiç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1192, N'Bilecik Merkez', 11, N'Bilecik', N'TR4131100000000', N'bilecik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1193, N'Bingöl Merkez', 12, N'Bingöl', N'TRB131200000000', N'bingöl')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1194, N'Birecik', 63, N'Şanlıurfa', N'TRC216302000000', N'birecik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1195, N'Bismil', 21, N'Diyarbakır', N'TRC222101000000', N'bismil')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1196, N'Bitlis Merkez', 13, N'Bitlis', N'TRB231300000000', N'bitlis')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1197, N'Bodrum', 48, N'Muğla', N'TR3234801000000', N'bodrum')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1198, N'Boğazlıyan', 66, N'Yozgat', N'TR7236603000000', N'boğazlıyan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1199, N'Bolu Merkez', 14, N'Bolu', N'TR4241400000000', N'bolu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1200, N'Bolvadin', 3, N'Afyonkarahisar', N'TR3320303000000', N'bolvadin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1201, N'Bor', 51, N'Niğde', N'TR7135102000000', N'bor')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1202, N'Borçka', 8, N'Artvin', N'TR9050803000000', N'borçka')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1203, N'Bornova', 35, N'İzmir', N'TR3103502000000', N'bornova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1204, N'Boyabat', 57, N'Sinop', N'TR8235702000000', N'boyabat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1205, N'Bozcaada', 17, N'Çanakkale', N'TR2221704000000', N'bozcaada')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1206, N'Bozdoğan', 9, N'Aydın', N'TR3210901000000', N'bozdoğan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1207, N'Bozkır', 42, N'Konya', N'TR5214209000000', N'bozkır')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1208, N'Bozkurt / Kastamonu', 37, N'Kastamonu', N'TR8213705000000', N'bozkurt  kastamonu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1209, N'Bozova', 63, N'Şanlıurfa', N'TRC216303000000', N'bozova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1210, N'Bozüyük', 11, N'Bilecik', N'TR4131101000000', N'bozüyük')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1211, N'Bucak', 15, N'Burdur', N'TR6131503000000', N'bucak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1212, N'Bulancak', 28, N'Giresun', N'TR9032802000000', N'bulancak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1213, N'Bulanık', 49, N'Muş', N'TRB224901000000', N'bulanık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1214, N'Buldan', 20, N'Denizli', N'TR3222008000000', N'buldan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1215, N'Burdur Merkez', 15, N'Burdur', N'TR6131500000000', N'burdur')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1216, N'Burhaniye', 10, N'Balıkesir', N'TR2211005000000', N'burhaniye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1217, N'Bursa Merkez', 16, N'Bursa', NULL, N'bursa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1218, N'Bünyan', 38, N'Kayseri', N'TR7213804000000', N'bünyan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1219, N'Ceyhan', 1, N'Adana', N'TR6210104000000', N'ceyhan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1220, N'Ceylanpınar', 63, N'Şanlıurfa', N'TRC216304000000', N'ceylanpınar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1221, N'Cide', 37, N'Kastamonu', N'TR8213706000000', N'cide')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1222, N'Cihanbeyli', 42, N'Konya', N'TR5214210000000', N'cihanbeyli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1223, N'Cizre', 73, N'Şırnak', N'TRC337302000000', N'cizre')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1224, N'Çal', 20, N'Denizli', N'TR3222009000000', N'çal')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1225, N'Çamardı', 51, N'Niğde', N'TR7135103000000', N'çamardı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1226, N'Çameli', 20, N'Denizli', N'TR3222010000000', N'çameli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1227, N'Çamlıdere', 6, N'Ankara', N'TR5100613000000', N'çamlıdere')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1228, N'Çamlıhemşin', 53, N'Rize', N'TR9045302000000', N'çamlıhemşin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1229, N'Çan', 17, N'Çanakkale', N'TR2221705000000', N'çan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1230, N'Çanakkale Merkez', 17, N'Çanakkale', N'TR2221700000000', N'çanakkale')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1231, N'Çankaya', 6, N'Ankara', N'TR5100602000000', N'çankaya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1232, N'Çankırı Merkez', 18, N'Çankırı', N'TR8221800000000', N'çankırı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1233, N'Çardak', 20, N'Denizli', N'TR3222011000000', N'çardak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1234, N'Çarşamba', 55, N'Samsun', N'TR8315505000000', N'çarşamba')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1235, N'Çat', 25, N'Erzurum', N'TRA112502000000', N'çat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1236, N'Çatak', 65, N'Van', N'TRB216504000000', N'çatak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1237, N'Çatalca', 34, N'İstanbul', N'TR1003429000000', N'çatalca')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1238, N'Çatalzeytin', 37, N'Kastamonu', N'TR8213707000000', N'çatalzeytin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1239, N'Çay', 3, N'Afyonkarahisar', N'TR3320304000000', N'çay')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1240, N'Çaycuma', 67, N'Zonguldak', N'TR8116702000000', N'çaycuma')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1241, N'Çayeli', 53, N'Rize', N'TR9045303000000', N'çayeli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1242, N'Çayıralan', 66, N'Yozgat', N'TR7236605000000', N'çayıralan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1243, N'Çayırlı', 24, N'Erzincan', N'TRA122401000000', N'çayırlı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1244, N'Çaykara', 61, N'Trabzon', N'TR9016106000000', N'çaykara')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1245, N'Çekerek', 66, N'Yozgat', N'TR7236606000000', N'çekerek')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1246, N'Çelikhan', 2, N'Adıyaman', N'TRC120202000000', N'çelikhan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1247, N'Çemişgezek', 62, N'Tunceli', N'TRB146201000000', N'çemişgezek')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1248, N'Çerkeş', 18, N'Çankırı', N'TR8221803000000', N'çerkeş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1249, N'Çermik', 21, N'Diyarbakır', N'TRC222102000000', N'çermik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1250, N'Çerkezköy', 59, N'Tekirdağ', N'TR2115901000000', N'çerkezköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1251, N'Çeşme', 35, N'İzmir', N'TR3103514000000', N'çeşme')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1252, N'Çıldır', 75, N'Ardahan', N'TRA247501000000', N'çıldır')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1253, N'Çınar', 21, N'Diyarbakır', N'TRC222103000000', N'çınar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1254, N'Çiçekdağı', 40, N'Kırşehir', N'TR7154004000000', N'çiçekdağı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1255, N'Çifteler', 26, N'Eskişehir', N'TR4122603000000', N'çifteler')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1256, N'Çine', 9, N'Aydın', N'TR3210903000000', N'çine')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1257, N'Çivril', 20, N'Denizli', N'TR3222012000000', N'çivril')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1258, N'Çorlu', 59, N'Tekirdağ', N'TR2115902000000', N'çorlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1259, N'Çorum Merkez', 19, N'Çorum', N'TR8331900000000', N'çorum')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1260, N'Çubuk', 6, N'Ankara', N'TR5100614000000', N'çubuk')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1261, N'Çukurca', 30, N'Hakkari', N'TRB243001000000', N'çukurca')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1262, N'Çumra', 42, N'Konya', N'TR5214212000000', N'çumra')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1263, N'Çüngüş', 21, N'Diyarbakır', N'TRC222104000000', N'çüngüş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1264, N'Daday', 37, N'Kastamonu', N'TR8213708000000', N'daday')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1265, N'Darende', 44, N'Malatya', N'TRB114405000000', N'darende')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1266, N'Datça', 48, N'Muğla', N'TR3234803000000', N'datça')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1267, N'Dazkırı', 3, N'Afyonkarahisar', N'TR3320306000000', N'dazkırı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1268, N'Delice', 71, N'Kırıkkale', N'TR7117104000000', N'delice')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1269, N'Demirci', 45, N'Manisa', N'TR3314504000000', N'demirci')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1270, N'Demirköy', 39, N'Kırklareli', N'TR2133902000000', N'demirköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1271, N'Denizli Merkez', 20, N'Denizli', N'TR3222000000000', N'denizli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1272, N'Dereli', 28, N'Giresun', N'TR9032805000000', N'dereli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1273, N'Derik', 47, N'Mardin', N'TRC314702000000', N'derik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1274, N'Derinkuyu', 50, N'Nevşehir', N'TR7145003000000', N'derinkuyu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1275, N'Develi', 38, N'Kayseri', N'TR7213805000000', N'develi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1276, N'Devrek', 67, N'Zonguldak', N'TR8116703000000', N'devrek')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1277, N'Devrekani', 37, N'Kastamonu', N'TR8213709000000', N'devrekani')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1278, N'Dicle', 21, N'Diyarbakır', N'TRC222105000000', N'dicle')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1279, N'Digor', 36, N'Kars', N'TRA223603000000', N'digor')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1280, N'Dikili', 35, N'İzmir', N'TR3103515000000', N'dikili')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1281, N'Dinar', 3, N'Afyonkarahisar', N'TR3320307000000', N'dinar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1282, N'Divriği', 58, N'Sivas', N'TR7225803000000', N'divriği')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1283, N'Diyadin', 4, N'Ağrı', N'TRA210401000000', N'diyadin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1284, N'Diyarbakır Merkez', 21, N'Diyarbakır', N'TRC222100000000', N'diyarbakır')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1285, N'Doğanhisar', 42, N'Konya', N'TR5214215000000', N'doğanhisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1286, N'Doğanşehir', 44, N'Malatya', N'TRB114406000000', N'doğanşehir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1287, N'Doğubayazıt', 4, N'Ağrı', N'TRA210402000000', N'doğubayazıt')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1288, N'Domaniç', 43, N'Kütahya', N'TR3334304000000', N'domaniç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1289, N'Dörtyol', 31, N'Hatay', N'TR6313103000000', N'dörtyol')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1290, N'Durağan', 57, N'Sinop', N'TR8235704000000', N'durağan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1291, N'Dursunbey', 10, N'Balıkesir', N'TR2211006000000', N'dursunbey')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1292, N'Düzce Merkez', 81, N'Düzce', N'TR4238100000000', N'düzce')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1293, N'Eceabat', 17, N'Çanakkale', N'TR2221706000000', N'eceabat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1294, N'Edremit / Balıkesir', 10, N'Balıkesir', N'TR2211007000000', N'edremit  balıkesir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1295, N'Edirne Merkez', 22, N'Edirne', N'TR2122200000000', N'edirne')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1296, N'Eflani', 78, N'Karabük', N'TR8127801000000', N'eflani')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1297, N'Eğirdir', 32, N'Isparta', N'TR6123203000000', N'eğirdir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1298, N'Elazığ Merkez', 23, N'Elazığ', N'TRB122300000000', N'elazığ')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1299, N'Elbistan', 46, N'Kahramanmaraş', N'TR6324605000000', N'elbistan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1300, N'Eldivan', 18, N'Çankırı', N'TR8221804000000', N'eldivan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1301, N'Eleşkirt', 4, N'Ağrı', N'TRA210403000000', N'eleşkirt')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1302, N'Elmadağ', 6, N'Ankara', N'TR5100615000000', N'elmadağ')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1303, N'Elmalı', 7, N'Antalya', N'TR6110703000000', N'elmalı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1304, N'Emet', 43, N'Kütahya', N'TR3334306000000', N'emet')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1305, N'Eminönü', 34, N'İstanbul', N'TR1003410000000', N'eminönü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1306, N'Emirdağ', 3, N'Afyonkarahisar', N'TR3320308000000', N'emirdağ')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1307, N'Enez', 22, N'Edirne', N'TR2122201000000', N'enez')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1308, N'Erbaa', 60, N'Tokat', N'TR8326004000000', N'erbaa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1309, N'Erciş', 65, N'Van', N'TRB216506000000', N'erciş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1310, N'Erdek', 10, N'Balıkesir', N'TR2211008000000', N'erdek')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1311, N'Erdemli', 33, N'Mersin', N'TR6223305000000', N'erdemli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1312, N'Ereğli / Konya', 42, N'Konya', N'TR5214217000000', N'ereğli  konya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1313, N'Ereğli / Zonguldak', 67, N'Zonguldak', N'TR8116704000000', N'ereğli  zonguldak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1314, N'Erfelek', 57, N'Sinop', N'TR8235705000000', N'erfelek')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1315, N'Ergani', 21, N'Diyarbakır', N'TRC222107000000', N'ergani')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1316, N'Ermenek', 70, N'Karaman', N'TR5227003000000', N'ermenek')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1317, N'Eruh', 56, N'Siirt', N'TRC345603000000', N'eruh')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1318, N'Erzincan Merkez', 24, N'Erzincan', N'TRA122400000000', N'erzincan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1319, N'Erzurum Merkez', 25, N'Erzurum', N'TRA112500000000', N'erzurum')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1320, N'Espiye', 28, N'Giresun', N'TR9032807000000', N'espiye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1321, N'Eskipazar', 78, N'Karabük', N'TR8127802000000', N'eskipazar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1322, N'Eskişehir Merkez', 26, N'Eskişehir', N'TR4122600000000', N'eskişehir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1323, N'Eşme', 64, N'Uşak', N'TR3346402000000', N'eşme')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1324, N'Eynesil', 28, N'Giresun', N'TR9032808000000', N'eynesil')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1325, N'Eyüp', 34, N'İstanbul', N'TR1003412000000', N'eyüp')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1326, N'Ezine', 17, N'Çanakkale', N'TR2221707000000', N'ezine')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1327, N'Fatih', 34, N'İstanbul', N'TR1003413000000', N'fatih')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1328, N'Fatsa', 52, N'Ordu', N'TR9025206000000', N'fatsa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1329, N'Feke', 1, N'Adana', N'TR6210105000000', N'feke')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1330, N'Felahiye', 38, N'Kayseri', N'TR7213806000000', N'felahiye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1331, N'Fethiye', 48, N'Muğla', N'TR3234804000000', N'fethiye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1332, N'Fındıklı', 53, N'Rize', N'TR9045305000000', N'fındıklı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1333, N'Finike', 7, N'Antalya', N'TR6110704000000', N'finike')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1334, N'Foça', 35, N'İzmir', N'TR3103516000000', N'foça')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1335, N'Gaziantep Merkez', 27, N'Gaziantep', NULL, N'gaziantep')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1336, N'Gaziosmanpaşa', 34, N'İstanbul', N'TR1003414000000', N'gaziosmanpaşa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1337, N'Gazipaşa', 7, N'Antalya', N'TR6110705000000', N'gazipaşa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1338, N'Gebze', 41, N'Kocaeli', N'TR4214101000000', N'gebze')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1339, N'Gediz', 43, N'Kütahya', N'TR3334307000000', N'gediz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1340, N'Gelibolu', 17, N'Çanakkale', N'TR2221708000000', N'gelibolu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1341, N'Gelendost', 32, N'Isparta', N'TR6123204000000', N'gelendost')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1342, N'Gemerek', 58, N'Sivas', N'TR7225805000000', N'gemerek')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1343, N'Gemlik', 16, N'Bursa', N'TR4111605000000', N'gemlik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1344, N'Genç', 12, N'Bingöl', N'TRB131202000000', N'genç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1345, N'Gercüş', 72, N'Batman', N'TRC327202000000', N'gercüş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1346, N'Gerede', 14, N'Bolu', N'TR4241402000000', N'gerede')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1347, N'Gerger', 2, N'Adıyaman', N'TRC120203000000', N'gerger')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1348, N'Germencik', 9, N'Aydın', N'TR3210905000000', N'germencik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1349, N'Gerze', 57, N'Sinop', N'TR8235706000000', N'gerze')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1350, N'Gevaş', 65, N'Van', N'TRB216507000000', N'gevaş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1351, N'Geyve', 54, N'Sakarya', N'TR4225404000000', N'geyve')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1352, N'Giresun Merkez', 28, N'Giresun', N'TR9032800000000', N'giresun')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1353, N'Göksun', 46, N'Kahramanmaraş', N'TR6324606000000', N'göksun')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1354, N'Gölbaşı / Adıyaman', 2, N'Adıyaman', N'TRC120204000000', N'gölbaşı  adıyaman')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1355, N'Gölcük', 41, N'Kocaeli', N'TR4214102000000', N'gölcük')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1356, N'Göle', 75, N'Ardahan', N'TRA247503000000', N'göle')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1357, N'Gölhisar', 15, N'Burdur', N'TR6131506000000', N'gölhisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1358, N'Gölköy', 52, N'Ordu', N'TR9025207000000', N'gölköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1359, N'Gölpazarı', 11, N'Bilecik', N'TR4131102000000', N'gölpazarı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1360, N'Gönen / Balıkesir', 10, N'Balıkesir', N'TR2211010000000', N'gönen  balıkesir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1361, N'Görele', 28, N'Giresun', N'TR9032809000000', N'görele')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1362, N'Gördes', 45, N'Manisa', N'TR3314506000000', N'gördes')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1363, N'Göynücek', 5, N'Amasya', N'TR8340501000000', N'göynücek')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1364, N'Göynük', 14, N'Bolu', N'TR4241403000000', N'göynük')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1365, N'Güdül', 6, N'Ankara', N'TR5100617000000', N'güdül')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1366, N'Gülnar', 33, N'Mersin', N'TR6223306000000', N'gülnar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1367, N'Gülşehir', 50, N'Nevşehir', N'TR7145004000000', N'gülşehir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1368, N'Gümüşhacıköy', 5, N'Amasya', N'TR8340502000000', N'gümüşhacıköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1369, N'Gümüşhane Merkez', 29, N'Gümüşhane', N'TR9062900000000', N'gümüşhane')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1370, N'Gündoğmuş', 7, N'Antalya', N'TR6110706000000', N'gündoğmuş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1371, N'Güney', 20, N'Denizli', N'TR3222013000000', N'güney')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1372, N'Gürpınar', 65, N'Van', N'TRB216508000000', N'gürpınar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1373, N'Gürün', 58, N'Sivas', N'TR7225807000000', N'gürün')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1374, N'Hacıbektaş', 50, N'Nevşehir', N'TR7145005000000', N'hacıbektaş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1375, N'Hadim', 42, N'Konya', N'TR5214219000000', N'hadim')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1376, N'Hafik', 58, N'Sivas', N'TR7225808000000', N'hafik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1377, N'Hakkari Merkez', 30, N'Hakkari', N'TRB243000000000', N'hakkari')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1378, N'Halfeti', 63, N'Şanlıurfa', N'TRC216305000000', N'halfeti')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1379, N'Hamur', 4, N'Ağrı', N'TRA210404000000', N'hamur')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1380, N'Hanak', 75, N'Ardahan', N'TRA247504000000', N'hanak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1381, N'Hani', 21, N'Diyarbakır', N'TRC222108000000', N'hani')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1382, N'Hassa', 31, N'Hatay', N'TR6313105000000', N'hassa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1383, N'Hatay Merkez', 31, N'Hatay', N'TR6313100000000', N'hatay')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1384, N'Havran', 10, N'Balıkesir', N'TR2211011000000', N'havran')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1385, N'Havsa', 22, N'Edirne', N'TR2122202000000', N'havsa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1386, N'Havza', 55, N'Samsun', N'TR8315506000000', N'havza')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1387, N'Haymana', 6, N'Ankara', N'TR5100618000000', N'haymana')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1388, N'Hayrabolu', 59, N'Tekirdağ', N'TR2115903000000', N'hayrabolu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1389, N'Hazro', 21, N'Diyarbakır', N'TRC222109000000', N'hazro')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1390, N'Hekimhan', 44, N'Malatya', N'TRB114408000000', N'hekimhan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1391, N'Hendek', 54, N'Sakarya', N'TR4225405000000', N'hendek')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1392, N'Hınıs', 25, N'Erzurum', N'TRA112503000000', N'hınıs')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1393, N'Hilvan', 63, N'Şanlıurfa', N'TRC216307000000', N'hilvan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1394, N'Hizan', 13, N'Bitlis', N'TRB231304000000', N'hizan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1395, N'Hopa', 8, N'Artvin', N'TR9050804000000', N'hopa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1396, N'Horasan', 25, N'Erzurum', N'TRA112504000000', N'horasan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1397, N'Hozat', 62, N'Tunceli', N'TRB146202000000', N'hozat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1398, N'Iğdır Merkez', 76, N'Iğdır', N'TRA237600000000', N'ığdır')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1399, N'Ilgaz', 18, N'Çankırı', N'TR8221805000000', N'ılgaz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1400, N'Ilgın', 42, N'Konya', N'TR5214222000000', N'ılgın')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1401, N'Isparta Merkez', 32, N'Isparta', N'TR6123200000000', N'ısparta')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1402, N'İçel Merkez', 33, N'Mersin', N'TR6223300000000', N'içel')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1403, N'İdil', 73, N'Şırnak', N'TRC337304000000', N'idil')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1404, N'İhsaniye', 3, N'Afyonkarahisar', N'TR3320311000000', N'ihsaniye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1405, N'İkizdere', 53, N'Rize', N'TR9045308000000', N'ikizdere')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1406, N'İliç', 24, N'Erzincan', N'TRA122402000000', N'iliç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1407, N'İmranlı', 58, N'Sivas', N'TR7225809000000', N'imranlı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1408, N'Gökçeada', 17, N'Çanakkale', N'TR2221709000000', N'gökçeada')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1409, N'İncesu', 38, N'Kayseri', N'TR7213808000000', N'incesu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1410, N'İnebolu', 37, N'Kastamonu', N'TR8213713000000', N'inebolu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1411, N'İnegöl', 16, N'Bursa', N'TR4111608000000', N'inegöl')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1412, N'İpsala', 22, N'Edirne', N'TR2122203000000', N'ipsala')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1413, N'İskenderun', 31, N'Hatay', N'TR6313106000000', N'iskenderun')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1414, N'İskilip', 19, N'Çorum', N'TR8331905000000', N'iskilip')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1415, N'İslahiye', 27, N'Gaziantep', N'TRC112704000000', N'islahiye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1416, N'İspir', 25, N'Erzurum', N'TRA112506000000', N'ispir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1417, N'İstanbul Merkez', 34, N'İstanbul', NULL, N'istanbul')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1418, N'İvrindi', 10, N'Balıkesir', N'TR2211012000000', N'ivrindi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1419, N'İzmir Merkez', 35, N'İzmir', NULL, N'izmir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1420, N'İznik', 16, N'Bursa', N'TR4111609000000', N'iznik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1421, N'Kadıköy', 34, N'İstanbul', N'TR1003416000000', N'kadıköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1422, N'Kadınhanı', 42, N'Konya', N'TR5214223000000', N'kadınhanı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1423, N'Kadirli', 80, N'Osmaniye', N'TR6338004000000', N'kadirli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1424, N'Kağızman', 36, N'Kars', N'TRA223604000000', N'kağızman')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1425, N'Kahta', 2, N'Adıyaman', N'TRC120205000000', N'kahta')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1426, N'Kale / Denizli', 20, N'Denizli', N'TR3222015000000', N'kale  denizli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1427, N'Kalecik', 6, N'Ankara', N'TR5100619000000', N'kalecik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1428, N'Kalkandere', 53, N'Rize', N'TR9045310000000', N'kalkandere')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1429, N'Kaman', 40, N'Kırşehir', N'TR7154005000000', N'kaman')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1430, N'Kandıra', 41, N'Kocaeli', N'TR4214103000000', N'kandıra')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1431, N'Kangal', 58, N'Sivas', N'TR7225810000000', N'kangal')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1432, N'Karaburun', 35, N'İzmir', N'TR3103517000000', N'karaburun')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1433, N'Karabük Merkez', 78, N'Karabük', N'TR8127800000000', N'karabük')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1434, N'Karacabey', 16, N'Bursa', N'TR4111610000000', N'karacabey')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1435, N'Karacasu', 9, N'Aydın', N'TR3210907000000', N'karacasu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1436, N'Karahallı', 64, N'Uşak', N'TR3346403000000', N'karahallı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1437, N'Karaisalı', 1, N'Adana', N'TR6210107000000', N'karaisalı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1438, N'Karakoçan', 23, N'Elazığ', N'TRB122305000000', N'karakoçan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1439, N'Karaman Merkez', 70, N'Karaman', N'TR5227000000000', N'karaman')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1440, N'Karamürsel', 41, N'Kocaeli', N'TR4214104000000', N'karamürsel')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1441, N'Karapınar', 42, N'Konya', N'TR5214224000000', N'karapınar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1442, N'Karasu', 54, N'Sakarya', N'TR4225407000000', N'karasu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1443, N'Karataş', 1, N'Adana', N'TR6210108000000', N'karataş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1444, N'Karayazı', 25, N'Erzurum', N'TRA112508000000', N'karayazı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1445, N'Kargı', 19, N'Çorum', N'TR8331906000000', N'kargı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1446, N'Karlıova', 12, N'Bingöl', N'TRB131203000000', N'karlıova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1447, N'Kars Merkez', 36, N'Kars', N'TRA223600000000', N'kars')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1448, N'Karşıyaka', 35, N'İzmir', N'TR3103507000000', N'karşıyaka')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1449, N'Kartal', 34, N'İstanbul', N'TR1003418000000', N'kartal')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1450, N'Kastamonu Merkez', 37, N'Kastamonu', N'TR8213700000000', N'kastamonu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1451, N'Kaş', 7, N'Antalya', N'TR6110709000000', N'kaş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1452, N'Kavak', 55, N'Samsun', N'TR8315507000000', N'kavak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1453, N'Kaynarca', 54, N'Sakarya', N'TR4225408000000', N'kaynarca')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1454, N'Kayseri Merkez', 38, N'Kayseri', NULL, N'kayseri')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1455, N'Keban', 23, N'Elazığ', N'TRB122306000000', N'keban')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1456, N'Keçiborlu', 32, N'Isparta', N'TR6123206000000', N'keçiborlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1457, N'Keles', 16, N'Bursa', N'TR4111611000000', N'keles')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1458, N'Kelkit', 29, N'Gümüşhane', N'TR9062901000000', N'kelkit')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1459, N'Kemah', 24, N'Erzincan', N'TRA122403000000', N'kemah')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1460, N'Kemaliye', 24, N'Erzincan', N'TRA122404000000', N'kemaliye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1461, N'Kemalpaşa', 35, N'İzmir', N'TR3103518000000', N'kemalpaşa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1462, N'Kepsut', 10, N'Balıkesir', N'TR2211013000000', N'kepsut')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1463, N'Keskin', 71, N'Kırıkkale', N'TR7117106000000', N'keskin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1464, N'Keşan', 22, N'Edirne', N'TR2122204000000', N'keşan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1465, N'Keşap', 28, N'Giresun', N'TR9032811000000', N'keşap')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1466, N'Kıbrıscık', 14, N'Bolu', N'TR4241404000000', N'kıbrıscık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1467, N'Kınık', 35, N'İzmir', N'TR3103519000000', N'kınık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1468, N'Kırıkhan', 31, N'Hatay', N'TR6313107000000', N'kırıkhan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1469, N'Kırıkkale Merkez', 71, N'Kırıkkale', N'TR7117100000000', N'kırıkkale')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1470, N'Kırkağaç', 45, N'Manisa', N'TR3314507000000', N'kırkağaç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1471, N'Kırklareli Merkez', 39, N'Kırklareli', N'TR2133900000000', N'kırklareli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1472, N'Kırşehir Merkez', 40, N'Kırşehir', N'TR7154000000000', N'kırşehir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1473, N'Kızılcahamam', 6, N'Ankara', N'TR5100621000000', N'kızılcahamam')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1474, N'Kızıltepe', 47, N'Mardin', N'TRC314703000000', N'kızıltepe')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1475, N'Kiğı', 12, N'Bingöl', N'TRB131204000000', N'kiğı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1476, N'Kilis Merkez', 79, N'Kilis', N'TRC137900000000', N'kilis')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1477, N'Kiraz', 35, N'İzmir', N'TR3103520000000', N'kiraz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1478, N'Kocaeli Merkez', 41, N'Kocaeli', N'TR4214100000000', N'kocaeli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1479, N'Koçarlı', 9, N'Aydın', N'TR3210909000000', N'koçarlı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1480, N'Kofçaz', 39, N'Kırklareli', N'TR2133903000000', N'kofçaz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1481, N'Konya Merkez', 42, N'Konya', NULL, N'konya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1482, N'Korgan', 52, N'Ordu', N'TR9025213000000', N'korgan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1483, N'Korkuteli', 7, N'Antalya', N'TR6110711000000', N'korkuteli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1484, N'Koyulhisar', 58, N'Sivas', N'TR7225811000000', N'koyulhisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1485, N'Kozaklı', 50, N'Nevşehir', N'TR7145006000000', N'kozaklı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1486, N'Kozan', 1, N'Adana', N'TR6210109000000', N'kozan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1487, N'Kozluk', 72, N'Batman', N'TRC327204000000', N'kozluk')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1488, N'Köyceğiz', 48, N'Muğla', N'TR3234806000000', N'köyceğiz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1489, N'Kula', 45, N'Manisa', N'TR3314509000000', N'kula')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1490, N'Kulp', 21, N'Diyarbakır', N'TRC222111000000', N'kulp')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1491, N'Kulu', 42, N'Konya', N'TR5214225000000', N'kulu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1492, N'Kumluca', 7, N'Antalya', N'TR6110712000000', N'kumluca')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1493, N'Kumru', 52, N'Ordu', N'TR9025214000000', N'kumru')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1494, N'Kurşunlu', 18, N'Çankırı', N'TR8221808000000', N'kurşunlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1495, N'Kurtalan', 56, N'Siirt', N'TRC345604000000', N'kurtalan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1496, N'Kurucaşile', 74, N'Bartın', N'TR8137402000000', N'kurucaşile')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1497, N'Kuşadası', 9, N'Aydın', N'TR3210911000000', N'kuşadası')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1498, N'Kuyucak', 9, N'Aydın', N'TR3210912000000', N'kuyucak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1499, N'Küre', 37, N'Kastamonu', N'TR8213714000000', N'küre')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1500, N'Kütahya Merkez', 43, N'Kütahya', N'TR3334300000000', N'kütahya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1501, N'Ladik', 55, N'Samsun', N'TR8315508000000', N'ladik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1502, N'Lalapaşa', 22, N'Edirne', N'TR2122205000000', N'lalapaşa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1503, N'Lapseki', 17, N'Çanakkale', N'TR2221710000000', N'lapseki')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1504, N'Lice', 21, N'Diyarbakır', N'TRC222112000000', N'lice')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1505, N'Lüleburgaz', 39, N'Kırklareli', N'TR2133904000000', N'lüleburgaz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1506, N'Maden', 23, N'Elazığ', N'TRB122308000000', N'maden')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1507, N'Maçka', 61, N'Trabzon', N'TR9016111000000', N'maçka')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1508, N'Mahmudiye', 26, N'Eskişehir', N'TR4122607000000', N'mahmudiye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1509, N'Malatya Merkez', 44, N'Malatya', N'TRB114400000000', N'malatya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1510, N'Malazgirt', 49, N'Muş', N'TRB224904000000', N'malazgirt')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1511, N'Malkara', 59, N'Tekirdağ', N'TR2115904000000', N'malkara')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1512, N'Manavgat', 7, N'Antalya', N'TR6110713000000', N'manavgat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1513, N'Manisa Merkez', 45, N'Manisa', N'TR3314500000000', N'manisa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1514, N'Manyas', 10, N'Balıkesir', N'TR2211014000000', N'manyas')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1515, N'Kahramanmaraş Merkez', 46, N'Kahramanmaraş', N'TR6324600000000', N'kahramanmaraş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1516, N'Mardin Merkez', 47, N'Mardin', N'TRC314700000000', N'mardin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1517, N'Marmaris', 48, N'Muğla', N'TR3234807000000', N'marmaris')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1518, N'Mazgirt', 62, N'Tunceli', N'TRB146203000000', N'mazgirt')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1519, N'Mazıdağı', 47, N'Mardin', N'TRC314704000000', N'mazıdağı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1520, N'Mecitözü', 19, N'Çorum', N'TR8331908000000', N'mecitözü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1521, N'Menemen', 35, N'İzmir', N'TR3103522000000', N'menemen')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1522, N'Mengen', 14, N'Bolu', N'TR4241405000000', N'mengen')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1523, N'Meriç', 22, N'Edirne', N'TR2122206000000', N'meriç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1524, N'Merzifon', 5, N'Amasya', N'TR8340504000000', N'merzifon')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1525, N'Mesudiye', 52, N'Ordu', N'TR9025215000000', N'mesudiye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1526, N'Midyat', 47, N'Mardin', N'TRC314705000000', N'midyat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1527, N'Mihalıççık', 26, N'Eskişehir', N'TR4122609000000', N'mihalıççık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1528, N'Milas', 48, N'Muğla', N'TR3234808000000', N'milas')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1529, N'Mucur', 40, N'Kırşehir', N'TR7154006000000', N'mucur')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1530, N'Mudanya', 16, N'Bursa', N'TR4111613000000', N'mudanya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1531, N'Mudurnu', 14, N'Bolu', N'TR4241406000000', N'mudurnu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1532, N'Muğla Merkez', 48, N'Muğla', N'TR3234800000000', N'muğla')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1533, N'Muradiye', 65, N'Van', N'TRB216509000000', N'muradiye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1534, N'Muş Merkez', 49, N'Muş', N'TRB224900000000', N'muş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1535, N'Mustafakemalpaşa', 16, N'Bursa', N'TR4111614000000', N'mustafakemalpaşa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1536, N'Mut', 33, N'Mersin', N'TR6223307000000', N'mut')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1537, N'Mutki', 13, N'Bitlis', N'TRB231305000000', N'mutki')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1538, N'Muratlı', 59, N'Tekirdağ', N'TR2115906000000', N'muratlı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1539, N'Nallıhan', 6, N'Ankara', N'TR5100622000000', N'nallıhan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1540, N'Narman', 25, N'Erzurum', N'TRA112510000000', N'narman')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1541, N'Nazımiye', 62, N'Tunceli', N'TRB146204000000', N'nazımiye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1542, N'Nazilli', 9, N'Aydın', N'TR3210913000000', N'nazilli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1543, N'Nevşehir Merkez', 50, N'Nevşehir', N'TR7145000000000', N'nevşehir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1544, N'Niğde Merkez', 51, N'Niğde', N'TR7135100000000', N'niğde')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1545, N'Niksar', 60, N'Tokat', N'TR8326005000000', N'niksar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1546, N'Nizip', 27, N'Gaziantep', N'TRC112706000000', N'nizip')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1547, N'Nusaybin', 47, N'Mardin', N'TRC314706000000', N'nusaybin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1548, N'Of', 61, N'Trabzon', N'TR9016112000000', N'of')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1549, N'Oğuzeli', 27, N'Gaziantep', N'TRC112708000000', N'oğuzeli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1550, N'Oltu', 25, N'Erzurum', N'TRA112511000000', N'oltu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1551, N'Olur', 25, N'Erzurum', N'TRA112512000000', N'olur')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1552, N'Ordu Merkez', 52, N'Ordu', N'TR9025200000000', N'ordu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1553, N'Orhaneli', 16, N'Bursa', N'TR4111615000000', N'orhaneli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1554, N'Orhangazi', 16, N'Bursa', N'TR4111616000000', N'orhangazi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1555, N'Orta', 18, N'Çankırı', N'TR8221809000000', N'orta')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1556, N'Ortaköy / Çorum', 19, N'Çorum', N'TR8331910000000', N'ortaköy  çorum')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1557, N'Ortaköy', 68, N'Aksaray', N'TR7126805000000', N'ortaköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1558, N'Osmancık', 19, N'Çorum', N'TR8331911000000', N'osmancık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1559, N'Osmaneli', 11, N'Bilecik', N'TR4131104000000', N'osmaneli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1560, N'Osmaniye Merkez', 80, N'Osmaniye', N'TR6338000000000', N'osmaniye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1561, N'Ovacık / Karabük', 78, N'Karabük', N'TR8127803000000', N'ovacık  karabük')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1562, N'Ovacık / Tunceli', 62, N'Tunceli', N'TRB146205000000', N'ovacık  tunceli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1563, N'Ödemiş', 35, N'İzmir', N'TR3103523000000', N'ödemiş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1564, N'Ömerli', 47, N'Mardin', N'TRC314707000000', N'ömerli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1565, N'Özalp', 65, N'Van', N'TRB216510000000', N'özalp')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1566, N'Palu', 23, N'Elazığ', N'TRB122309000000', N'palu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1567, N'Pasinler', 25, N'Erzurum', N'TRA112513000000', N'pasinler')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1568, N'Patnos', 4, N'Ağrı', N'TRA210405000000', N'patnos')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1569, N'Pazar / Rize', 53, N'Rize', N'TR9045311000000', N'pazar  rize')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1570, N'Pazarcık', 46, N'Kahramanmaraş', N'TR6324608000000', N'pazarcık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1571, N'Pazaryeri', 11, N'Bilecik', N'TR4131105000000', N'pazaryeri')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1572, N'Pehlivanköy', 39, N'Kırklareli', N'TR2133905000000', N'pehlivanköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1573, N'Perşembe', 52, N'Ordu', N'TR9025216000000', N'perşembe')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1574, N'Pertek', 62, N'Tunceli', N'TRB146206000000', N'pertek')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1575, N'Pervari', 56, N'Siirt', N'TRC345605000000', N'pervari')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1576, N'Pınarbaşı / Kayseri', 38, N'Kayseri', N'TR7213810000000', N'pınarbaşı  kayseri')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1577, N'Pınarhisar', 39, N'Kırklareli', N'TR2133906000000', N'pınarhisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1578, N'Polatlı', 6, N'Ankara', N'TR5100623000000', N'polatlı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1579, N'Posof', 75, N'Ardahan', N'TRA247505000000', N'posof')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1580, N'Pozantı', 1, N'Adana', N'TR6210110000000', N'pozantı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1581, N'Pülümür', 62, N'Tunceli', N'TRB146207000000', N'pülümür')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1582, N'Pütürge', 44, N'Malatya', N'TRB114411000000', N'pütürge')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1583, N'Refahiye', 24, N'Erzincan', N'TRA122406000000', N'refahiye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1584, N'Reşadiye', 60, N'Tokat', N'TR8326007000000', N'reşadiye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1585, N'Reyhanlı', 31, N'Hatay', N'TR6313109000000', N'reyhanlı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1586, N'Rize Merkez', 53, N'Rize', N'TR9045300000000', N'rize')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1587, N'Safranbolu', 78, N'Karabük', N'TR8127804000000', N'safranbolu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1588, N'Saimbeyli', 1, N'Adana', N'TR6210111000000', N'saimbeyli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1589, N'Sakarya Merkez', 54, N'Sakarya', N'TR4225400000000', N'sakarya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1590, N'Salihli', 45, N'Manisa', N'TR3314510000000', N'salihli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1591, N'Samandağ', 31, N'Hatay', N'TR6313110000000', N'samandağ')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1592, N'Samsat', 2, N'Adıyaman', N'TRC120206000000', N'samsat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1593, N'Samsun Merkez', 55, N'Samsun', N'TR8315500000000', N'samsun')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1594, N'Sandıklı', 3, N'Afyonkarahisar', N'TR3320314000000', N'sandıklı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1595, N'Sapanca', 54, N'Sakarya', N'TR4225411000000', N'sapanca')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1596, N'Saray / Tekirdağ', 59, N'Tekirdağ', N'TR2115907000000', N'saray  tekirdağ')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1597, N'Sarayköy', 20, N'Denizli', N'TR3222016000000', N'sarayköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1598, N'Sarayönü', 42, N'Konya', N'TR5214226000000', N'sarayönü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1599, N'Sarıcakaya', 26, N'Eskişehir', N'TR4122610000000', N'sarıcakaya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1600, N'Sarıgöl', 45, N'Manisa', N'TR3314511000000', N'sarıgöl')
GO

--
-- Data for table dbo.Ilce  (LIMIT 500,500)
--

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1601, N'Sarıkamış', 36, N'Kars', N'TRA223605000000', N'sarıkamış')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1602, N'Sarıkaya', 66, N'Yozgat', N'TR7236609000000', N'sarıkaya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1603, N'Sarıoğlan', 38, N'Kayseri', N'TR7213811000000', N'sarıoğlan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1604, N'Sarıyer', 34, N'İstanbul', N'TR1003422000000', N'sarıyer')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1605, N'Sarız', 38, N'Kayseri', N'TR7213812000000', N'sarız')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1606, N'Saruhanlı', 45, N'Manisa', N'TR3314512000000', N'saruhanlı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1607, N'Sason', 72, N'Batman', N'TRC327205000000', N'sason')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1608, N'Savaştepe', 10, N'Balıkesir', N'TR2211016000000', N'savaştepe')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1609, N'Savur', 47, N'Mardin', N'TRC314708000000', N'savur')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1610, N'Seben', 14, N'Bolu', N'TR4241407000000', N'seben')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1611, N'Seferihisar', 35, N'İzmir', N'TR3103524000000', N'seferihisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1612, N'Selçuk', 35, N'İzmir', N'TR3103525000000', N'selçuk')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1613, N'Selendi', 45, N'Manisa', N'TR3314513000000', N'selendi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1614, N'Selim', 36, N'Kars', N'TRA223606000000', N'selim')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1615, N'Senirkent', 32, N'Isparta', N'TR6123207000000', N'senirkent')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1616, N'Serik', 7, N'Antalya', N'TR6110714000000', N'serik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1617, N'Seydişehir', 42, N'Konya', N'TR5214227000000', N'seydişehir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1618, N'Seyitgazi', 26, N'Eskişehir', N'TR4122611000000', N'seyitgazi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1619, N'Sındırgı', 10, N'Balıkesir', N'TR2211017000000', N'sındırgı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1620, N'Siirt Merkez', 56, N'Siirt', N'TRC345600000000', N'siirt')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1621, N'Silifke', 33, N'Mersin', N'TR6223308000000', N'silifke')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1622, N'Silivri', 34, N'İstanbul', N'TR1003430000000', N'silivri')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1623, N'Silopi', 73, N'Şırnak', N'TRC337305000000', N'silopi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1624, N'Silvan', 21, N'Diyarbakır', N'TRC222113000000', N'silvan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1625, N'Simav', 43, N'Kütahya', N'TR3334310000000', N'simav')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1626, N'Sinanpaşa', 3, N'Afyonkarahisar', N'TR3320315000000', N'sinanpaşa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1627, N'Sinop Merkez', 57, N'Sinop', N'TR8235700000000', N'sinop')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1628, N'Sivas Merkez', 58, N'Sivas', N'TR7225800000000', N'sivas')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1629, N'Sivaslı', 64, N'Uşak', N'TR3346404000000', N'sivaslı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1630, N'Siverek', 63, N'Şanlıurfa', N'TRC216308000000', N'siverek')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1631, N'Sivrice', 23, N'Elazığ', N'TRB122310000000', N'sivrice')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1632, N'Sivrihisar', 26, N'Eskişehir', N'TR4122612000000', N'sivrihisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1633, N'Solhan', 12, N'Bingöl', N'TRB131205000000', N'solhan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1634, N'Soma', 45, N'Manisa', N'TR3314514000000', N'soma')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1635, N'Sorgun', 66, N'Yozgat', N'TR7236610000000', N'sorgun')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1636, N'Söğüt', 11, N'Bilecik', N'TR4131106000000', N'söğüt')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1637, N'Söke', 9, N'Aydın', N'TR3210914000000', N'söke')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1638, N'Sulakyurt', 71, N'Kırıkkale', N'TR7117107000000', N'sulakyurt')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1639, N'Sultandağı', 3, N'Afyonkarahisar', N'TR3320316000000', N'sultandağı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1640, N'Sultanhisar', 9, N'Aydın', N'TR3210915000000', N'sultanhisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1641, N'Suluova', 5, N'Amasya', N'TR8340505000000', N'suluova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1642, N'Sungurlu', 19, N'Çorum', N'TR8331912000000', N'sungurlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1643, N'Suruç', 63, N'Şanlıurfa', N'TRC216309000000', N'suruç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1644, N'Susurluk', 10, N'Balıkesir', N'TR2211018000000', N'susurluk')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1645, N'Susuz', 36, N'Kars', N'TRA223607000000', N'susuz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1646, N'Suşehri', 58, N'Sivas', N'TR7225812000000', N'suşehri')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1647, N'Sürmene', 61, N'Trabzon', N'TR9016113000000', N'sürmene')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1648, N'Sütçüler', 32, N'Isparta', N'TR6123208000000', N'sütçüler')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1649, N'Şabanözü', 18, N'Çankırı', N'TR8221810000000', N'şabanözü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1650, N'Şarkışla', 58, N'Sivas', N'TR7225813000000', N'şarkışla')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1651, N'Şarkikaraağaç', 32, N'Isparta', N'TR6123209000000', N'şarkikaraağaç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1652, N'Şarköy', 59, N'Tekirdağ', N'TR2115908000000', N'şarköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1653, N'Şavşat', 8, N'Artvin', N'TR9050806000000', N'şavşat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1654, N'Şebinkarahisar', 28, N'Giresun', N'TR9032813000000', N'şebinkarahisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1655, N'Şefaatli', 66, N'Yozgat', N'TR7236611000000', N'şefaatli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1656, N'Şemdinli', 30, N'Hakkari', N'TRB243002000000', N'şemdinli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1657, N'Şenkaya', 25, N'Erzurum', N'TRA112515000000', N'şenkaya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1658, N'Şereflikoçhisar', 6, N'Ankara', N'TR5100624000000', N'şereflikoçhisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1659, N'Şile', 34, N'İstanbul', N'TR1003432000000', N'şile')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1660, N'Şiran', 29, N'Gümüşhane', N'TR9062904000000', N'şiran')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1661, N'Şırnak Merkez', 73, N'Şırnak', N'TRC337300000000', N'şırnak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1662, N'Şirvan', 56, N'Siirt', N'TRC345606000000', N'şirvan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1663, N'Şişli', 34, N'İstanbul', N'TR1003423000000', N'şişli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1664, N'Şuhut', 3, N'Afyonkarahisar', N'TR3320317000000', N'şuhut')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1665, N'Tarsus', 33, N'Mersin', N'TR6223309000000', N'tarsus')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1666, N'Taşköprü', 37, N'Kastamonu', N'TR8213718000000', N'taşköprü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1667, N'Taşlıçay', 4, N'Ağrı', N'TRA210406000000', N'taşlıçay')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1668, N'Taşova', 5, N'Amasya', N'TR8340506000000', N'taşova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1669, N'Tatvan', 13, N'Bitlis', N'TRB231306000000', N'tatvan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1670, N'Tavas', 20, N'Denizli', N'TR3222018000000', N'tavas')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1671, N'Tavşanlı', 43, N'Kütahya', N'TR3334312000000', N'tavşanlı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1672, N'Tefenni', 15, N'Burdur', N'TR6131509000000', N'tefenni')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1673, N'Tekirdağ Merkez', 59, N'Tekirdağ', N'TR2115900000000', N'tekirdağ')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1674, N'Tekman', 25, N'Erzurum', N'TRA112516000000', N'tekman')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1675, N'Tercan', 24, N'Erzincan', N'TRA122407000000', N'tercan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1676, N'Terme', 55, N'Samsun', N'TR8315512000000', N'terme')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1677, N'Tire', 35, N'İzmir', N'TR3103526000000', N'tire')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1678, N'Tirebolu', 28, N'Giresun', N'TR9032814000000', N'tirebolu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1679, N'Tokat Merkez', 60, N'Tokat', N'TR8326000000000', N'tokat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1680, N'Tomarza', 38, N'Kayseri', N'TR7213814000000', N'tomarza')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1681, N'Tonya', 61, N'Trabzon', N'TR9016115000000', N'tonya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1682, N'Torbalı', 35, N'İzmir', N'TR3103527000000', N'torbalı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1683, N'Tortum', 25, N'Erzurum', N'TRA112517000000', N'tortum')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1684, N'Torul', 29, N'Gümüşhane', N'TR9062905000000', N'torul')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1685, N'Tosya', 37, N'Kastamonu', N'TR8213719000000', N'tosya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1686, N'Trabzon Merkez', 61, N'Trabzon', N'TR9016100000000', N'trabzon')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1687, N'Tufanbeyli', 1, N'Adana', N'TR6210112000000', N'tufanbeyli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1688, N'Tunceli Merkez', 62, N'Tunceli', N'TRB146200000000', N'tunceli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1689, N'Turgutlu', 45, N'Manisa', N'TR3314515000000', N'turgutlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1690, N'Turhal', 60, N'Tokat', N'TR8326009000000', N'turhal')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1691, N'Tutak', 4, N'Ağrı', N'TRA210407000000', N'tutak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1692, N'Tuzluca', 76, N'Iğdır', N'TRA237603000000', N'tuzluca')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1693, N'Türkeli', 57, N'Sinop', N'TR8235708000000', N'türkeli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1694, N'Türkoğlu', 46, N'Kahramanmaraş', N'TR6324609000000', N'türkoğlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1695, N'Ula', 48, N'Muğla', N'TR3234810000000', N'ula')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1696, N'Ulubey / Ordu', 52, N'Ordu', N'TR9025217000000', N'ulubey  ordu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1697, N'Ulubey / Uşak', 64, N'Uşak', N'TR3346405000000', N'ulubey  uşak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1698, N'Uludere', 73, N'Şırnak', N'TRC337306000000', N'uludere')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1699, N'Uluborlu', 32, N'Isparta', N'TR6123210000000', N'uluborlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1700, N'Ulukışla', 51, N'Niğde', N'TR7135105000000', N'ulukışla')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1701, N'Ulus', 74, N'Bartın', N'TR8137403000000', N'ulus')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1702, N'Şanlıurfa Merkez', 63, N'Şanlıurfa', N'TRC216300000000', N'şanlıurfa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1703, N'Urla', 35, N'İzmir', N'TR3103528000000', N'urla')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1704, N'Uşak Merkez', 64, N'Uşak', N'TR3346400000000', N'uşak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1705, N'Uzunköprü', 22, N'Edirne', N'TR2122208000000', N'uzunköprü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1706, N'Ünye', 52, N'Ordu', N'TR9025218000000', N'ünye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1707, N'Ürgüp', 50, N'Nevşehir', N'TR7145007000000', N'ürgüp')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1708, N'Üsküdar', 34, N'İstanbul', N'TR1003426000000', N'üsküdar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1709, N'Vakfıkebir', 61, N'Trabzon', N'TR9016116000000', N'vakfıkebir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1710, N'Van Merkez', 65, N'Van', N'TRB216500000000', N'van')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1711, N'Varto', 49, N'Muş', N'TRB224905000000', N'varto')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1712, N'Vezirköprü', 55, N'Samsun', N'TR8315513000000', N'vezirköprü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1713, N'Viranşehir', 63, N'Şanlıurfa', N'TRC216310000000', N'viranşehir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1714, N'Vize', 39, N'Kırklareli', N'TR2133907000000', N'vize')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1715, N'Yahyalı', 38, N'Kayseri', N'TR7213815000000', N'yahyalı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1716, N'Yalova Merkez', 77, N'Yalova', N'TR4257700000000', N'yalova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1717, N'Yalvaç', 32, N'Isparta', N'TR6123211000000', N'yalvaç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1718, N'Yapraklı', 18, N'Çankırı', N'TR8221811000000', N'yapraklı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1719, N'Yatağan', 48, N'Muğla', N'TR3234811000000', N'yatağan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1720, N'Yavuzeli', 27, N'Gaziantep', N'TRC112709000000', N'yavuzeli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1721, N'Yayladağı', 31, N'Hatay', N'TR6313111000000', N'yayladağı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1722, N'Yenice / Çanakkale', 17, N'Çanakkale', N'TR2221711000000', N'yenice  çanakkale')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1723, N'Yenimahalle', 6, N'Ankara', N'TR5100608000000', N'yenimahalle')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1724, N'Yenipazar / Aydın', 9, N'Aydın', N'TR3210916000000', N'yenipazar  aydın')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1725, N'Yenişehir / Bursa', 16, N'Bursa', N'TR4111617000000', N'yenişehir  bursa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1726, N'Yerköy', 66, N'Yozgat', N'TR7236613000000', N'yerköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1727, N'Yeşilhisar', 38, N'Kayseri', N'TR7213816000000', N'yeşilhisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1728, N'Yeşilova', 15, N'Burdur', N'TR6131510000000', N'yeşilova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1729, N'Yeşilyurt / Malatya', 44, N'Malatya', N'TRB114413000000', N'yeşilyurt  malatya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1730, N'Yığılca', 81, N'Düzce', N'TR4238107000000', N'yığılca')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1731, N'Yıldızeli', 58, N'Sivas', N'TR7225815000000', N'yıldızeli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1732, N'Yomra', 61, N'Trabzon', N'TR9016117000000', N'yomra')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1733, N'Yozgat Merkez', 66, N'Yozgat', N'TR7236600000000', N'yozgat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1734, N'Yumurtalık', 1, N'Adana', N'TR6210113000000', N'yumurtalık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1735, N'Yunak', 42, N'Konya', N'TR5214231000000', N'yunak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1736, N'Yusufeli', 8, N'Artvin', N'TR9050807000000', N'yusufeli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1737, N'Yüksekova', 30, N'Hakkari', N'TRB243003000000', N'yüksekova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1738, N'Zara', 58, N'Sivas', N'TR7225816000000', N'zara')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1739, N'Zeytinburnu', 34, N'İstanbul', N'TR1003427000000', N'zeytinburnu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1740, N'Zile', 60, N'Tokat', N'TR8326011000000', N'zile')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1741, N'Zonguldak Merkez', 67, N'Zonguldak', N'TR8116700000000', N'zonguldak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1742, N'Dalaman', 48, N'Muğla', N'TR3234802000000', N'dalaman')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1743, N'Düziçi', 80, N'Osmaniye', N'TR6338002000000', N'düziçi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1744, N'Gölbaşı / Ankara', 6, N'Ankara', N'TR5100604000000', N'gölbaşı  ankara')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1745, N'Keçiören', 6, N'Ankara', N'TR5100605000000', N'keçiören')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1746, N'Mamak', 6, N'Ankara', N'TR5100606000000', N'mamak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1747, N'Sincan', 6, N'Ankara', N'TR5100607000000', N'sincan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1748, N'Yüreğir', 1, N'Adana', N'TR6210102000000', N'yüreğir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1749, N'Acıgöl', 50, N'Nevşehir', N'TR7145001000000', N'acıgöl')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1750, N'Adaklı', 12, N'Bingöl', N'TRB131201000000', N'adaklı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1751, N'Ahmetli', 45, N'Manisa', N'TR3314501000000', N'ahmetli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1752, N'Akkışla', 38, N'Kayseri', N'TR7213803000000', N'akkışla')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1753, N'Akören', 42, N'Konya', N'TR5214205000000', N'akören')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1754, N'Akpınar', 40, N'Kırşehir', N'TR7154002000000', N'akpınar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1755, N'Aksu / Isparta', 32, N'Isparta', N'TR6123201000000', N'aksu  ısparta')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1756, N'Akyaka', 36, N'Kars', N'TRA223601000000', N'akyaka')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1757, N'Aladağ', 1, N'Adana', N'TR6210103000000', N'aladağ')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1758, N'Alaplı', 67, N'Zonguldak', N'TR8116701000000', N'alaplı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1759, N'Alpu', 26, N'Eskişehir', N'TR4122601000000', N'alpu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1760, N'Altınekin', 42, N'Konya', N'TR5214207000000', N'altınekin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1761, N'Amasra', 74, N'Bartın', N'TR8137401000000', N'amasra')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1762, N'Arıcak', 23, N'Elazığ', N'TRB122303000000', N'arıcak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1763, N'Asarcık', 55, N'Samsun', N'TR8315502000000', N'asarcık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1764, N'Aslanapa', 43, N'Kütahya', N'TR3334302000000', N'aslanapa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1765, N'Atkaracalar', 18, N'Çankırı', N'TR8221801000000', N'atkaracalar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1766, N'Aydıncık / Mersin', 33, N'Mersin', N'TR6223302000000', N'aydıncık  mersin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1767, N'Aydıntepe', 69, N'Bayburt', N'TRA136901000000', N'aydıntepe')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1768, N'Ayrancı', 70, N'Karaman', N'TR5227001000000', N'ayrancı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1769, N'Babadağ', 20, N'Denizli', N'TR3222003000000', N'babadağ')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1770, N'Bahçesaray', 65, N'Van', N'TRB216501000000', N'bahçesaray')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1771, N'Başmakçı', 3, N'Afyonkarahisar', N'TR3320301000000', N'başmakçı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1772, N'Battalgazi', 44, N'Malatya', N'TRB114404000000', N'battalgazi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1773, N'Bayat / Afyonkarahisar', 3, N'Afyonkarahisar', N'TR3320302000000', N'bayat  afyonkarahisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1774, N'Bekilli', 20, N'Denizli', N'TR3222005000000', N'bekilli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1775, N'Beşikdüzü', 61, N'Trabzon', N'TR9016104000000', N'beşikdüzü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1776, N'Beydağ', 35, N'İzmir', N'TR3103513000000', N'beydağ')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1777, N'Beylikova', 26, N'Eskişehir', N'TR4122602000000', N'beylikova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1778, N'Boğazkale', 19, N'Çorum', N'TR8331903000000', N'boğazkale')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1779, N'Bozyazı', 33, N'Mersin', N'TR6223303000000', N'bozyazı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1780, N'Buca', 35, N'İzmir', N'TR3103503000000', N'buca')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1781, N'Buharkent', 9, N'Aydın', N'TR3210902000000', N'buharkent')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1782, N'Büyükçekmece', 34, N'İstanbul', N'TR1003428000000', N'büyükçekmece')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1783, N'Büyükorhan', 16, N'Bursa', N'TR4111604000000', N'büyükorhan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1784, N'Cumayeri', 81, N'Düzce', N'TR4238102000000', N'cumayeri')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1785, N'Çağlıyancerit', 46, N'Kahramanmaraş', N'TR6324603000000', N'çağlıyancerit')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1786, N'Çaldıran', 65, N'Van', N'TRB216503000000', N'çaldıran')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1787, N'Dargeçit', 47, N'Mardin', N'TRC314701000000', N'dargeçit')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1788, N'Demirözü', 69, N'Bayburt', N'TRA136902000000', N'demirözü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1789, N'Derebucak', 42, N'Konya', N'TR5214214000000', N'derebucak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1790, N'Dumlupınar', 43, N'Kütahya', N'TR3334305000000', N'dumlupınar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1791, N'Eğil', 21, N'Diyarbakır', N'TRC222106000000', N'eğil')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1792, N'Erzin', 31, N'Hatay', N'TR6313104000000', N'erzin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1793, N'Gölmarmara', 45, N'Manisa', N'TR3314505000000', N'gölmarmara')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1794, N'Gölyaka', 81, N'Düzce', N'TR4238104000000', N'gölyaka')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1795, N'Gülyalı', 52, N'Ordu', N'TR9025208000000', N'gülyalı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1796, N'Güneysu', 53, N'Rize', N'TR9045306000000', N'güneysu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1797, N'Gürgentepe', 52, N'Ordu', N'TR9025209000000', N'gürgentepe')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1798, N'Güroymak', 13, N'Bitlis', N'TRB231303000000', N'güroymak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1799, N'Harmancık', 16, N'Bursa', N'TR4111607000000', N'harmancık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1800, N'Harran', 63, N'Şanlıurfa', N'TRC216306000000', N'harran')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1801, N'Hasköy', 49, N'Muş', N'TRB224902000000', N'hasköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1802, N'Hisarcık', 43, N'Kütahya', N'TR3334308000000', N'hisarcık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1803, N'Honaz', 20, N'Denizli', N'TR3222014000000', N'honaz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1804, N'Hüyük', 42, N'Konya', N'TR5214221000000', N'hüyük')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1805, N'İhsangazi', 37, N'Kastamonu', N'TR8213712000000', N'ihsangazi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1806, N'İmamoğlu', 1, N'Adana', N'TR6210106000000', N'imamoğlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1807, N'İncirliova', 9, N'Aydın', N'TR3210906000000', N'incirliova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1808, N'İnönü', 26, N'Eskişehir', N'TR4122606000000', N'inönü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1809, N'İscehisar', 3, N'Afyonkarahisar', N'TR3320312000000', N'iscehisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1810, N'Kağıthane', 34, N'İstanbul', N'TR1003417000000', N'kağıthane')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1811, N'Demre', 7, N'Antalya', N'TR6110716000000', N'demre')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1812, N'Karaçoban', 25, N'Erzurum', N'TRA112507000000', N'karaçoban')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1813, N'Karamanlı', 15, N'Burdur', N'TR6131507000000', N'karamanlı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1814, N'Karatay', 42, N'Konya', N'TR5214201000000', N'karatay')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1815, N'Kazan', 6, N'Ankara', N'TR5100620000000', N'kazan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1816, N'Kemer / Burdur', 15, N'Burdur', N'TR6131508000000', N'kemer  burdur')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1817, N'Kızılırmak', 18, N'Çankırı', N'TR8221806000000', N'kızılırmak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1818, N'Kocaali', 54, N'Sakarya', N'TR4225409000000', N'kocaali')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1819, N'Konak', 35, N'İzmir', N'TR3103508000000', N'konak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1820, N'Kovancılar', 23, N'Elazığ', N'TRB122307000000', N'kovancılar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1821, N'Körfez', 41, N'Kocaeli', N'TR4214105000000', N'körfez')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1822, N'Köse', 29, N'Gümüşhane', N'TR9062902000000', N'köse')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1823, N'Küçükçekmece', 34, N'İstanbul', N'TR1003419000000', N'küçükçekmece')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1824, N'Marmara', 10, N'Balıkesir', N'TR2211015000000', N'marmara')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1825, N'Marmaraereğlisi', 59, N'Tekirdağ', N'TR2115905000000', N'marmaraereğlisi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1826, N'Menderes', 35, N'İzmir', N'TR3103521000000', N'menderes')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1827, N'Meram', 42, N'Konya', N'TR5214202000000', N'meram')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1828, N'Murgul', 8, N'Artvin', N'TR9050805000000', N'murgul')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1829, N'Nilüfer', 16, N'Bursa', N'TR4111601000000', N'nilüfer')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1830, N'Ondokuzmayıs', 55, N'Samsun', N'TR8315509000000', N'ondokuzmayıs')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1831, N'Ortaca', 48, N'Muğla', N'TR3234809000000', N'ortaca')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1832, N'Osmangazi', 16, N'Bursa', N'TR4111602000000', N'osmangazi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1833, N'Pamukova', 54, N'Sakarya', N'TR4225410000000', N'pamukova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1834, N'Pazar / Tokat', 60, N'Tokat', N'TR8326006000000', N'pazar  tokat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1835, N'Pendik', 34, N'İstanbul', N'TR1003421000000', N'pendik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1836, N'Pınarbaşı / Kastamonu', 37, N'Kastamonu', N'TR8213715000000', N'pınarbaşı  kastamonu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1837, N'Piraziz', 28, N'Giresun', N'TR9032812000000', N'piraziz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1838, N'Salıpazarı', 55, N'Samsun', N'TR8315510000000', N'salıpazarı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1839, N'Selçuklu', 42, N'Konya', N'TR5214203000000', N'selçuklu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1840, N'Serinhisar', 20, N'Denizli', N'TR3222017000000', N'serinhisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1841, N'Şahinbey', 27, N'Gaziantep', N'TRC112701000000', N'şahinbey')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1842, N'Şalpazarı', 61, N'Trabzon', N'TR9016114000000', N'şalpazarı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1843, N'Şaphane', 43, N'Kütahya', N'TR3334311000000', N'şaphane')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1844, N'Şehitkamil', 27, N'Gaziantep', N'TRC112702000000', N'şehitkamil')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1845, N'Şenpazar', 37, N'Kastamonu', N'TR8213717000000', N'şenpazar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1846, N'Talas', 38, N'Kayseri', N'TR7213813000000', N'talas')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1847, N'Taraklı', 54, N'Sakarya', N'TR4225412000000', N'taraklı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1848, N'Taşkent', 42, N'Konya', N'TR5214228000000', N'taşkent')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1849, N'Tekkeköy', 55, N'Samsun', N'TR8315511000000', N'tekkeköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1850, N'Uğurludağ', 19, N'Çorum', N'TR8331913000000', N'uğurludağ')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1851, N'Uzundere', 25, N'Erzurum', N'TRA112518000000', N'uzundere')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1852, N'Ümraniye', 34, N'İstanbul', N'TR1003425000000', N'ümraniye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1853, N'Üzümlü', 24, N'Erzincan', N'TRA122408000000', N'üzümlü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1854, N'Yağlıdere', 28, N'Giresun', N'TR9032815000000', N'yağlıdere')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1855, N'Yayladere', 12, N'Bingöl', N'TRB131206000000', N'yayladere')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1856, N'Yenice / Karabük', 78, N'Karabük', N'TR8127805000000', N'yenice  karabük')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1857, N'Yenipazar / Bilecik', 11, N'Bilecik', N'TR4131107000000', N'yenipazar  bilecik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1858, N'Yeşilyurt / Tokat', 60, N'Tokat', N'TR8326010000000', N'yeşilyurt  tokat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1859, N'Yıldırım', 16, N'Bursa', N'TR4111603000000', N'yıldırım')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1860, N'Ağaçören', 68, N'Aksaray', N'TR7126801000000', N'ağaçören')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1861, N'Güzelyurt', 68, N'Aksaray', N'TR7126804000000', N'güzelyurt')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1862, N'Kazımkarabekir', 70, N'Karaman', N'TR5227004000000', N'kazımkarabekir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1863, N'Kocasinan', 38, N'Kayseri', N'TR7213801000000', N'kocasinan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1864, N'Melikgazi', 38, N'Kayseri', N'TR7213802000000', N'melikgazi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1865, N'Pazaryolu', 25, N'Erzurum', N'TRA112514000000', N'pazaryolu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1866, N'Sarıyahşi', 68, N'Aksaray', N'TR7126806000000', N'sarıyahşi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1867, N'Ağlı', 37, N'Kastamonu', N'TR8213702000000', N'ağlı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1868, N'Ahırlı', 42, N'Konya', N'TR5214204000000', N'ahırlı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1869, N'Akçakent', 40, N'Kırşehir', N'TR7154001000000', N'akçakent')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1870, N'Akıncılar', 58, N'Sivas', N'TR7225801000000', N'akıncılar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1871, N'Akköy', 20, N'Denizli', N'TR3222002000000', N'akköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1872, N'Akyurt', 6, N'Ankara', N'TR5100609000000', N'akyurt')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1873, N'Alacakaya', 23, N'Elazığ', N'TRB122302000000', N'alacakaya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1874, N'Altınyayla / Burdur', 15, N'Burdur', N'TR6131502000000', N'altınyayla  burdur')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1875, N'Altınyayla / Sivas', 58, N'Sivas', N'TR7225802000000', N'altınyayla  sivas')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1876, N'Altunhisar', 51, N'Niğde', N'TR7135101000000', N'altunhisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1877, N'Aydıncık / Yozgat', 66, N'Yozgat', N'TR7236602000000', N'aydıncık  yozgat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1878, N'Aydınlar', 56, N'Siirt', N'TRC345601000000', N'aydınlar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1879, N'Ayvacık / Samsun', 55, N'Samsun', N'TR8315503000000', N'ayvacık  samsun')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1880, N'Bahşili', 71, N'Kırıkkale', N'TR7117101000000', N'bahşili')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1881, N'Baklan', 20, N'Denizli', N'TR3222004000000', N'baklan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1882, N'Balışeyh', 71, N'Kırıkkale', N'TR7117102000000', N'balışeyh')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1883, N'Başçiftlik', 60, N'Tokat', N'TR8326003000000', N'başçiftlik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1884, N'Başyayla', 70, N'Karaman', N'TR5227002000000', N'başyayla')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1885, N'Bayramören', 18, N'Çankırı', N'TR8221802000000', N'bayramören')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1886, N'Bayrampaşa', 34, N'İstanbul', N'TR1003406000000', N'bayrampaşa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1887, N'Belen', 31, N'Hatay', N'TR6313102000000', N'belen')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1888, N'Beyağaç', 20, N'Denizli', N'TR3222006000000', N'beyağaç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1889, N'Bozkurt / Denizli', 20, N'Denizli', N'TR3222007000000', N'bozkurt  denizli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1890, N'Boztepe', 40, N'Kırşehir', N'TR7154003000000', N'boztepe')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1891, N'Çamaş', 52, N'Ordu', N'TR9025203000000', N'çamaş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1892, N'Çamlıyayla', 33, N'Mersin', N'TR6223304000000', N'çamlıyayla')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1893, N'Çamoluk', 28, N'Giresun', N'TR9032803000000', N'çamoluk')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1894, N'Çanakçı', 28, N'Giresun', N'TR9032804000000', N'çanakçı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1895, N'Çandır', 66, N'Yozgat', N'TR7236604000000', N'çandır')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1896, N'Çarşıbaşı', 61, N'Trabzon', N'TR9016105000000', N'çarşıbaşı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1897, N'Çatalpınar', 52, N'Ordu', N'TR9025204000000', N'çatalpınar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1898, N'Çavdarhisar', 43, N'Kütahya', N'TR3334303000000', N'çavdarhisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1899, N'Çavdır', 15, N'Burdur', N'TR6131504000000', N'çavdır')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1900, N'Çaybaşı', 52, N'Ordu', N'TR9025205000000', N'çaybaşı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1901, N'Çelebi', 71, N'Kırıkkale', N'TR7117103000000', N'çelebi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1902, N'Çeltik', 42, N'Konya', N'TR5214211000000', N'çeltik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1903, N'Çeltikçi', 15, N'Burdur', N'TR6131505000000', N'çeltikçi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1904, N'Çiftlik', 51, N'Niğde', N'TR7135104000000', N'çiftlik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1905, N'Çilimli', 81, N'Düzce', N'TR4238103000000', N'çilimli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1906, N'Çobanlar', 3, N'Afyonkarahisar', N'TR3320305000000', N'çobanlar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1907, N'Derbent', 42, N'Konya', N'TR5214213000000', N'derbent')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1908, N'Derepazarı', 53, N'Rize', N'TR9045304000000', N'derepazarı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1909, N'Dernekpazarı', 61, N'Trabzon', N'TR9016107000000', N'dernekpazarı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1910, N'Dikmen', 57, N'Sinop', N'TR8235703000000', N'dikmen')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1911, N'Dodurga', 19, N'Çorum', N'TR8331904000000', N'dodurga')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1912, N'Doğankent', 28, N'Giresun', N'TR9032806000000', N'doğankent')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1913, N'Doğanşar', 58, N'Sivas', N'TR7225804000000', N'doğanşar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1914, N'Doğanyol', 44, N'Malatya', N'TRB114407000000', N'doğanyol')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1915, N'Doğanyurt', 37, N'Kastamonu', N'TR8213710000000', N'doğanyurt')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1916, N'Dörtdivan', 14, N'Bolu', N'TR4241401000000', N'dörtdivan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1917, N'Düzköy', 61, N'Trabzon', N'TR9016108000000', N'düzköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1918, N'Edremit / Van', 65, N'Van', N'TRB216505000000', N'edremit  van')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1919, N'Ekinözü', 46, N'Kahramanmaraş', N'TR6324604000000', N'ekinözü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1920, N'Emirgazi', 42, N'Konya', N'TR5214216000000', N'emirgazi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1921, N'Eskil', 68, N'Aksaray', N'TR7126802000000', N'eskil')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1922, N'Etimesgut', 6, N'Ankara', N'TR5100603000000', N'etimesgut')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1923, N'Evciler', 3, N'Afyonkarahisar', N'TR3320309000000', N'evciler')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1924, N'Evren', 6, N'Ankara', N'TR5100616000000', N'evren')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1925, N'Ferizli', 54, N'Sakarya', N'TR4225401000000', N'ferizli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1926, N'Gökçebey', 67, N'Zonguldak', N'TR8116705000000', N'gökçebey')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1927, N'Gölova', 58, N'Sivas', N'TR7225806000000', N'gölova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1928, N'Gömeç', 10, N'Balıkesir', N'TR2211009000000', N'gömeç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1929, N'Gönen / Isparta', 32, N'Isparta', N'TR6123205000000', N'gönen  ısparta')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1930, N'Güce', 28, N'Giresun', N'TR9032810000000', N'güce')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1931, N'Güçlükonak', 73, N'Şırnak', N'TRC337303000000', N'güçlükonak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1932, N'Gülağaç', 68, N'Aksaray', N'TR7126803000000', N'gülağaç')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1933, N'Güneysınır', 42, N'Konya', N'TR5214218000000', N'güneysınır')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1934, N'Günyüzü', 26, N'Eskişehir', N'TR4122604000000', N'günyüzü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1935, N'Gürsu', 16, N'Bursa', N'TR4111606000000', N'gürsu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1936, N'Hacılar', 38, N'Kayseri', N'TR7213807000000', N'hacılar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1937, N'Halkapınar', 42, N'Konya', N'TR5214220000000', N'halkapınar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1938, N'Hamamözü', 5, N'Amasya', N'TR8340503000000', N'hamamözü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1939, N'Han', 26, N'Eskişehir', N'TR4122605000000', N'han')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1940, N'Hanönü', 37, N'Kastamonu', N'TR8213711000000', N'hanönü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1941, N'Hasankeyf', 72, N'Batman', N'TRC327203000000', N'hasankeyf')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1942, N'Hayrat', 61, N'Trabzon', N'TR9016109000000', N'hayrat')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1943, N'Hemşin', 53, N'Rize', N'TR9045307000000', N'hemşin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1944, N'Hocalar', 3, N'Afyonkarahisar', N'TR3320310000000', N'hocalar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1945, N'Aziziye', 25, N'Erzurum', N'TRA112520000000', N'aziziye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1946, N'İbradı', 7, N'Antalya', N'TR6110707000000', N'ibradı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1947, N'İkizce', 52, N'Ordu', N'TR9025210000000', N'ikizce')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1948, N'İnhisar', 11, N'Bilecik', N'TR4131103000000', N'inhisar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1949, N'İyidere', 53, N'Rize', N'TR9045309000000', N'iyidere')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1950, N'Kabadüz', 52, N'Ordu', N'TR9025211000000', N'kabadüz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1951, N'Kabataş', 52, N'Ordu', N'TR9025212000000', N'kabataş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1952, N'Kadışehri', 66, N'Yozgat', N'TR7236607000000', N'kadışehri')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1953, N'Kale / Malatya', 44, N'Malatya', N'TRB114409000000', N'kale  malatya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1954, N'Karakeçili', 71, N'Kırıkkale', N'TR7117105000000', N'karakeçili')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1955, N'Karapürçek', 54, N'Sakarya', N'TR4225406000000', N'karapürçek')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1956, N'Karkamış', 27, N'Gaziantep', N'TRC112705000000', N'karkamış')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1957, N'Karpuzlu', 9, N'Aydın', N'TR3210908000000', N'karpuzlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1958, N'Kavaklıdere', 48, N'Muğla', N'TR3234805000000', N'kavaklıdere')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1959, N'Kemer / Antalya', 7, N'Antalya', N'TR6110710000000', N'kemer  antalya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1960, N'Kestel', 16, N'Bursa', N'TR4111612000000', N'kestel')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1961, N'Kızılören', 3, N'Afyonkarahisar', N'TR3320313000000', N'kızılören')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1962, N'Kocaköy', 21, N'Diyarbakır', N'TRC222110000000', N'kocaköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1963, N'Korgun', 18, N'Çankırı', N'TR8221807000000', N'korgun')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1964, N'Korkut', 49, N'Muş', N'TRB224903000000', N'korkut')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1965, N'Köprübaşı / Manisa', 45, N'Manisa', N'TR3314508000000', N'köprübaşı  manisa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1966, N'Köprübaşı / Trabzon', 61, N'Trabzon', N'TR9016110000000', N'köprübaşı  trabzon')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1967, N'Köprüköy', 25, N'Erzurum', N'TRA112509000000', N'köprüköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1968, N'Köşk', 9, N'Aydın', N'TR3210910000000', N'köşk')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1969, N'Kuluncak', 44, N'Malatya', N'TRB114410000000', N'kuluncak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1970, N'Kumlu', 31, N'Hatay', N'TR6313108000000', N'kumlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1971, N'Kürtün', 29, N'Gümüşhane', N'TR9062903000000', N'kürtün')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1972, N'Laçin', 19, N'Çorum', N'TR8331907000000', N'laçin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1973, N'Mihalgazi', 26, N'Eskişehir', N'TR4122608000000', N'mihalgazi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1974, N'Nurdağı', 27, N'Gaziantep', N'TRC112707000000', N'nurdağı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1975, N'Nurhak', 46, N'Kahramanmaraş', N'TR6324607000000', N'nurhak')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1976, N'Oğuzlar', 19, N'Çorum', N'TR8331909000000', N'oğuzlar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1977, N'Otlukbeli', 24, N'Erzincan', N'TRA122405000000', N'otlukbeli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1978, N'Özvatan', 38, N'Kayseri', N'TR7213809000000', N'özvatan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1979, N'Pazarlar', 43, N'Kütahya', N'TR3334309000000', N'pazarlar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1980, N'Saray / Van', 65, N'Van', N'TRB216511000000', N'saray  van')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1981, N'Saraydüzü', 57, N'Sinop', N'TR8235707000000', N'saraydüzü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1982, N'Saraykent', 66, N'Yozgat', N'TR7236608000000', N'saraykent')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1983, N'Sarıveliler', 70, N'Karaman', N'TR5227005000000', N'sarıveliler')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1984, N'Seydiler', 37, N'Kastamonu', N'TR8213716000000', N'seydiler')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1985, N'Sincik', 2, N'Adıyaman', N'TRC120207000000', N'sincik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1986, N'Söğütlü', 54, N'Sakarya', N'TR4225402000000', N'söğütlü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1987, N'Sulusaray', 60, N'Tokat', N'TR8326008000000', N'sulusaray')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1988, N'Süloğlu', 22, N'Edirne', N'TR2122207000000', N'süloğlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1989, N'Tut', 2, N'Adıyaman', N'TRC120208000000', N'tut')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1990, N'Tuzlukçu', 42, N'Konya', N'TR5214229000000', N'tuzlukçu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1991, N'Ulaş', 58, N'Sivas', N'TR7225814000000', N'ulaş')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1992, N'Yahşihan', 71, N'Kırıkkale', N'TR7117108000000', N'yahşihan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1993, N'Yakakent', 55, N'Samsun', N'TR8315514000000', N'yakakent')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1994, N'Yalıhüyük', 42, N'Konya', N'TR5214230000000', N'yalıhüyük')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1995, N'Yazıhan', 44, N'Malatya', N'TRB114412000000', N'yazıhan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1996, N'Yedisu', 12, N'Bingöl', N'TRB131207000000', N'yedisu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1997, N'Yeniçağa', 14, N'Bolu', N'TR4241408000000', N'yeniçağa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (1998, N'Yenifakılı', 66, N'Yozgat', N'TR7236612000000', N'yenifakılı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2000, N'Didim', 9, N'Aydın', N'TR3210904000000', N'didim')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2001, N'Yenişarbademli', 32, N'Isparta', N'TR6123212000000', N'yenişarbademli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2002, N'Yeşilli', 47, N'Mardin', N'TRC314709000000', N'yeşilli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2003, N'Avcılar', 34, N'İstanbul', N'TR1003402000000', N'avcılar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2004, N'Bağcılar', 34, N'İstanbul', N'TR1003403000000', N'bağcılar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2005, N'Bahçelievler', 34, N'İstanbul', N'TR1003404000000', N'bahçelievler')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2006, N'Balçova', 35, N'İzmir', N'TR3103501000000', N'balçova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2007, N'Çiğli', 35, N'İzmir', N'TR3103504000000', N'çiğli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2008, N'Damal', 75, N'Ardahan', N'TRA247502000000', N'damal')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2009, N'Gaziemir', 35, N'İzmir', N'TR3103505000000', N'gaziemir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2010, N'Güngören', 34, N'İstanbul', N'TR1003415000000', N'güngören')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2011, N'Karakoyunlu', 76, N'Iğdır', N'TRA237602000000', N'karakoyunlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2012, N'Maltepe', 34, N'İstanbul', N'TR1003420000000', N'maltepe')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2013, N'Narlıdere', 35, N'İzmir', N'TR3103509000000', N'narlıdere')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2014, N'Sultanbeyli', 34, N'İstanbul', N'TR1003431000000', N'sultanbeyli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2015, N'Tuzla', 34, N'İstanbul', N'TR1003424000000', N'tuzla')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2016, N'Esenler', 34, N'İstanbul', N'TR1003411000000', N'esenler')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2017, N'Gümüşova', 81, N'Düzce', N'TR4238105000000', N'gümüşova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2018, N'Güzelbahçe', 35, N'İzmir', N'TR3103506000000', N'güzelbahçe')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2019, N'Altınova', 77, N'Yalova', N'TR4257701000000', N'altınova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2020, N'Armutlu', 77, N'Yalova', N'TR4257702000000', N'armutlu')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2021, N'Çınarcık', 77, N'Yalova', N'TR4257703000000', N'çınarcık')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2022, N'Çiftlikköy', 77, N'Yalova', N'TR4257704000000', N'çiftlikköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2023, N'Elbeyli', 79, N'Kilis', N'TRC137901000000', N'elbeyli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2024, N'Musabeyli', 79, N'Kilis', N'TRC137902000000', N'musabeyli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2025, N'Polateli', 79, N'Kilis', N'TRC137903000000', N'polateli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2026, N'Termal', 77, N'Yalova', N'TR4257705000000', N'termal')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2027, N'Hasanbeyli', 80, N'Osmaniye', N'TR6338003000000', N'hasanbeyli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2028, N'Sumbas', 80, N'Osmaniye', N'TR6338005000000', N'sumbas')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2029, N'Toprakkale', 80, N'Osmaniye', N'TR6338006000000', N'toprakkale')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2030, N'Derince', 41, N'Kocaeli', N'TR4214106000000', N'derince')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2031, N'Kaynaşlı', 81, N'Düzce', N'TR4238106000000', N'kaynaşlı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2032, N'Sarıçam', 1, N'Adana', N'TR6210115000000', N'sarıçam')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2033, N'Çukurova', 1, N'Adana', N'TR6210114000000', N'çukurova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2034, N'Pursaklar', 6, N'Ankara', N'TR5100625000000', N'pursaklar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2035, N'Aksu / Antalya', 7, N'Antalya', NULL, N'aksu  antalya')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2036, N'Döşemealtı', 7, N'Antalya', N'TR6110717000000', N'döşemealtı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2037, N'Kepez', 7, N'Antalya', N'TR6110718000000', N'kepez')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2038, N'Konyaaltı', 7, N'Antalya', N'TR6110715000000', N'konyaaltı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2039, N'Muratpaşa', 7, N'Antalya', N'TR6110719000000', N'muratpaşa')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2040, N'Bağlar', 21, N'Diyarbakır', N'TRC222115000000', N'bağlar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2041, N'Kayapınar', 21, N'Diyarbakır', N'TRC222117000000', N'kayapınar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2042, N'Sur', 21, N'Diyarbakır', N'TRC222114000000', N'sur')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2043, N'Yenişehir / Diyarbakır', 21, N'Diyarbakır', N'TRC222116000000', N'yenişehir  diyarbakır')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2044, N'Palandöken', 25, N'Erzurum', N'TRA112521000000', N'palandöken')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2045, N'Yakutiye', 25, N'Erzurum', N'TRA112519000000', N'yakutiye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2046, N'Odunpazarı', 26, N'Eskişehir', N'TR4122613000000', N'odunpazarı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2047, N'Tepebaşı', 26, N'Eskişehir', N'TR4122614000000', N'tepebaşı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2048, N'Arnavutköy', 34, N'İstanbul', N'TR1003434000000', N'arnavutköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2049, N'Ataşehir', 34, N'İstanbul', N'TR1003433000000', N'ataşehir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2050, N'Başakşehir', 34, N'İstanbul', N'TR1003435000000', N'başakşehir')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2051, N'Beylikdüzü', 34, N'İstanbul', N'TR1003436000000', N'beylikdüzü')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2052, N'Çekmeköy', 34, N'İstanbul', N'TR1003437000000', N'çekmeköy')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2053, N'Esenyurt', 34, N'İstanbul', N'TR1003438000000', N'esenyurt')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2054, N'Sancaktepe', 34, N'İstanbul', N'TR1003439000000', N'sancaktepe')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2055, N'Sultangazi', 34, N'İstanbul', N'TR1003440000000', N'sultangazi')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2056, N'Bayraklı', 35, N'İzmir', N'TR3103530000000', N'bayraklı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2057, N'Karabağlar', 35, N'İzmir', N'TR3103529000000', N'karabağlar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2058, N'Başiskele', 41, N'Kocaeli', N'TR4214111000000', N'başiskele')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2059, N'Çayırova', 41, N'Kocaeli', N'TR4214110000000', N'çayırova')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2060, N'Darıca', 41, N'Kocaeli', N'TR4214108000000', N'darıca')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2061, N'Dilovası', 41, N'Kocaeli', N'TR4214109000000', N'dilovası')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2062, N'İzmit', 41, N'Kocaeli', N'TR4214113000000', N'izmit')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2063, N'Kartepe', 41, N'Kocaeli', N'TR4214107000000', N'kartepe')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2064, N'Akdeniz', 33, N'Mersin', N'TR6223310000000', N'akdeniz')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2065, N'Mezitli', 33, N'Mersin', N'TR6223311000000', N'mezitli')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2066, N'Toroslar', 33, N'Mersin', N'TR6223312000000', N'toroslar')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2067, N'Yenişehir / Mersin', 33, N'Mersin', N'TR6223313000000', N'yenişehir  mersin')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2068, N'Adapazarı', 54, N'Sakarya', N'TR4225413000000', N'adapazarı')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2069, N'Arifiye', 54, N'Sakarya', N'TR4225414000000', N'arifiye')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2070, N'Erenler', 54, N'Sakarya', N'TR4225415000000', N'erenler')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2071, N'Serdivan', 54, N'Sakarya', N'TR4225416000000', N'serdivan')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2072, N'Atakum', 55, N'Samsun', N'TR8315515000000', N'atakum')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2073, N'Canik', 55, N'Samsun', N'TR8315517000000', N'canik')
GO

INSERT INTO [dbo].[Ilce] ([IlceKodu], [IlceAdi], [IlKodu], [IlAdi], [IegmIlceKodu], [IlceSon])
VALUES 
  (2074, N'İlkadım', 55, N'Samsun', N'TR8315518000000', N'ilkadım')
GO

--
-- Data for table dbo.KullaniciDersler  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[KullaniciDersler] ON
GO

INSERT INTO [dbo].[KullaniciDersler] ([Id], [KullaniciId], [DersId], [KullaniciOnayi], [UstOnay])
VALUES 
  (25, 1, 18, NULL, NULL)
GO

INSERT INTO [dbo].[KullaniciDersler] ([Id], [KullaniciId], [DersId], [KullaniciOnayi], [UstOnay])
VALUES 
  (26, 1, 20, NULL, NULL)
GO

INSERT INTO [dbo].[KullaniciDersler] ([Id], [KullaniciId], [DersId], [KullaniciOnayi], [UstOnay])
VALUES 
  (27, 1, 30, NULL, NULL)
GO

SET IDENTITY_INSERT [dbo].[KullaniciDersler] OFF
GO

--
-- Data for table dbo.KullaniciFormlar  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[KullaniciFormlar] ON
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (271, 1, 1, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (272, 1, 2, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (273, 1, 3, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (274, 1, 4, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (275, 1, 5, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (276, 1, 6, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (277, 1, 7, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (278, 1, 8, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (279, 1, 9, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (280, 1, 10, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (281, 1, 11, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (282, 1, 12, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (283, 1, 13, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (284, 1, 14, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (285, 1, 15, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (286, 1, 16, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (287, 1, 17, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (288, 1, 18, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (289, 1, 19, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (290, 1, 20, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (291, 1, 21, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (292, 1, 22, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (293, 1, 23, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (294, 3, 1, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (295, 3, 2, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (296, 3, 3, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (297, 3, 4, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (298, 3, 5, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (299, 3, 6, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (300, 3, 7, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (301, 3, 8, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (302, 3, 9, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (303, 3, 10, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (304, 3, 11, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (305, 3, 12, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (306, 3, 13, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (307, 3, 14, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (308, 3, 15, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (309, 3, 16, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (310, 3, 17, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (311, 3, 18, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (312, 3, 19, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (313, 3, 20, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (314, 3, 21, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (315, 3, 22, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (316, 3, 23, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (317, 13, 1, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (318, 13, 2, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (319, 13, 3, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (320, 13, 4, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (321, 13, 5, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (322, 13, 6, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (323, 13, 7, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (324, 13, 8, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (325, 13, 9, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (326, 13, 10, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (327, 13, 11, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (328, 13, 12, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (329, 13, 13, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (330, 13, 14, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (331, 13, 15, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (332, 13, 16, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (333, 13, 17, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (334, 13, 18, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (335, 13, 19, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (336, 13, 20, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (337, 13, 21, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (338, 13, 22, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (339, 13, 23, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (340, 14, 1, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (341, 14, 2, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (342, 14, 3, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (343, 14, 4, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (344, 14, 5, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (345, 14, 6, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (346, 14, 7, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (347, 14, 8, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (348, 14, 9, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (349, 14, 10, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (350, 14, 11, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (351, 14, 12, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (352, 14, 13, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (353, 14, 14, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (354, 14, 15, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (355, 14, 16, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (356, 14, 17, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (357, 14, 18, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (358, 14, 19, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (359, 14, 20, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (360, 14, 21, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (361, 14, 22, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (362, 14, 23, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (363, 14, 25, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (364, 14, 26, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (365, 14, 24, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (366, 1, 25, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (367, 1, 26, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (368, 1, 24, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (369, 13, 25, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (370, 13, 26, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (371, 13, 24, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (372, 15, 2, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (373, 15, 3, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (374, 15, 4, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (375, 15, 6, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (376, 15, 7, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (377, 15, 8, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (378, 15, 10, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (379, 15, 11, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (380, 15, 12, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (381, 15, 14, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (382, 15, 15, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (383, 15, 25, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (384, 15, 26, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (385, 15, 17, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (386, 15, 18, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (387, 15, 19, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (388, 15, 24, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (389, 15, 21, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (390, 15, 22, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (391, 15, 23, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (392, 1, 27, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (393, 1, 29, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (394, 1, 30, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (395, 1, 31, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (396, 14, 27, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (397, 14, 29, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (398, 14, 30, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (399, 14, 31, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (400, 14, 33, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (401, 14, 34, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (402, 14, 35, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (403, 1, 33, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (404, 1, 34, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (405, 1, 35, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (406, 13, 27, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (407, 13, 29, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (408, 13, 30, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (409, 13, 31, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (410, 13, 33, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (411, 13, 34, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (412, 13, 35, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (413, 13, 37, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (414, 3, 27, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (415, 3, 25, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (416, 3, 26, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (417, 3, 24, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (418, 3, 29, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (419, 3, 30, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (420, 3, 31, 0)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (421, 3, 33, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (422, 3, 34, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (423, 3, 35, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (424, 3, 37, 1)
GO

INSERT INTO [dbo].[KullaniciFormlar] ([Id], [KullaniciTipiId], [FormId], [FormYetki])
VALUES 
  (425, 3, 38, 1)
GO

SET IDENTITY_INSERT [dbo].[KullaniciFormlar] OFF
GO

--
-- Data for table dbo.Kullanicilar  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[Kullanicilar] ON
GO

INSERT INTO [dbo].[Kullanicilar] ([KullaniciId], [KullaniciAdi], [KullaniciSifre], [Adi], [Soyadi], [KullaniciTipi], [DogumTarihi], [Cinsiyet], [CepTel], [EvTel], [Email], [IlKodu], [IlceKodu], [Adres], [Resim], [KayitTarihi], [Onay], [DokumanAdres])
VALUES 
  (1, N'Admin', N'12345', N'Hakan', N'Tekedere', 1, NULL, 1, N'0544 614 43 08', N'0312 288 65 65', N'', 44, 1509, N'Kale Malatya..', N'Resim/Untitled-7.jpg', NULL, 1, N'~/Dokumanlar/HakanTekedere')
GO

INSERT INTO [dbo].[Kullanicilar] ([KullaniciId], [KullaniciAdi], [KullaniciSifre], [Adi], [Soyadi], [KullaniciTipi], [DogumTarihi], [Cinsiyet], [CepTel], [EvTel], [Email], [IlKodu], [IlceKodu], [Adres], [Resim], [KayitTarihi], [Onay], [DokumanAdres])
VALUES 
  (84, N'Ogretmen', N'Ogretmen', N'Ömer Faruk', N'Ocakoğlu', 14, '20140522', 1, N'05446144308', N'543543543543', N'test@tes.com', 6, 1745, N'test', N'Resim\Foto06052014005003.jpg', NULL, 1, N'~/Dokumanlar/OmerFarukOcakoglu')
GO

INSERT INTO [dbo].[Kullanicilar] ([KullaniciId], [KullaniciAdi], [KullaniciSifre], [Adi], [Soyadi], [KullaniciTipi], [DogumTarihi], [Cinsiyet], [CepTel], [EvTel], [Email], [IlKodu], [IlceKodu], [Adres], [Resim], [KayitTarihi], [Onay], [DokumanAdres])
VALUES 
  (85, N'Ogrenci', N'Ogrenci', N'Turgay', N'Akarsu', 3, '20140514', 1, N'05446144308', N'23432423423', N'test2@test.com', 6, 1387, N'teee', N'Resim/Ferhat.jpg', NULL, 1, NULL)
GO

INSERT INTO [dbo].[Kullanicilar] ([KullaniciId], [KullaniciAdi], [KullaniciSifre], [Adi], [Soyadi], [KullaniciTipi], [DogumTarihi], [Cinsiyet], [CepTel], [EvTel], [Email], [IlKodu], [IlceKodu], [Adres], [Resim], [KayitTarihi], [Onay], [DokumanAdres])
VALUES 
  (86, N'Seda', N'seda', N'Seda', N'Efe', 14, '20140515', 0, N'05646546546', N'6546545', N'tkecik@gmail.com', 8, 1395, N'test', N'Resim/images.jpg', NULL, 1, N'~/Dokumanlar/SedaEfe')
GO

INSERT INTO [dbo].[Kullanicilar] ([KullaniciId], [KullaniciAdi], [KullaniciSifre], [Adi], [Soyadi], [KullaniciTipi], [DogumTarihi], [Cinsiyet], [CepTel], [EvTel], [Email], [IlKodu], [IlceKodu], [Adres], [Resim], [KayitTarihi], [Onay], [DokumanAdres])
VALUES 
  (87, N'Yunus', N'yunus', N'Yunus', N'Dirican', 14, '19800505', 1, N'05323212145', N'03215465454', N'yunus@gmail.com', 71, 1638, N'', N'Resim/Untitled-9.jpg', NULL, 1, N'~/Dokumanlar/YunusDirican')
GO

INSERT INTO [dbo].[Kullanicilar] ([KullaniciId], [KullaniciAdi], [KullaniciSifre], [Adi], [Soyadi], [KullaniciTipi], [DogumTarihi], [Cinsiyet], [CepTel], [EvTel], [Email], [IlKodu], [IlceKodu], [Adres], [Resim], [KayitTarihi], [Onay], [DokumanAdres])
VALUES 
  (88, N'Burak', N'burak', N'Burak', N'Çubukçu', 3, '20140501', 1, N'05443214565', N'03125465452', N'test@test.com', 5, 1524, N'', N'', NULL, 1, NULL)
GO

SET IDENTITY_INSERT [dbo].[Kullanicilar] OFF
GO

--
-- Data for table dbo.KullaniciTipleri  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[KullaniciTipleri] ON
GO

INSERT INTO [dbo].[KullaniciTipleri] ([KullaniciTipId], [KullaniciTipAdi], [KullaniciTipAciklama], [KullaniciTipDurum])
VALUES 
  (1, N'Yönetici', N'Bu Grup Sitede Her Erişime Sahiptir', 0)
GO

INSERT INTO [dbo].[KullaniciTipleri] ([KullaniciTipId], [KullaniciTipAdi], [KullaniciTipAciklama], [KullaniciTipDurum])
VALUES 
  (3, N'Öğrenci', N'Ders Seçebilir. Dokuman Video goruntuleyebilir. Sınava Girebilir. Sınav Sonucları görüntüleyebilir.', 1)
GO

INSERT INTO [dbo].[KullaniciTipleri] ([KullaniciTipId], [KullaniciTipAdi], [KullaniciTipAciklama], [KullaniciTipDurum])
VALUES 
  (13, N'Idareci', N'Sadece Ders Ekleyebilir. Hocaların derslere atamasını yapabilir. Ogrenciyi Derse kabul edebilir', NULL)
GO

INSERT INTO [dbo].[KullaniciTipleri] ([KullaniciTipId], [KullaniciTipAdi], [KullaniciTipAciklama], [KullaniciTipDurum])
VALUES 
  (14, N'Öğrentmen', N'Ders İçeriği Ekleyebilir. Ders Seçebilir. Sınav Ekleyebilir', 1)
GO

INSERT INTO [dbo].[KullaniciTipleri] ([KullaniciTipId], [KullaniciTipAdi], [KullaniciTipAciklama], [KullaniciTipDurum])
VALUES 
  (15, N'Araştırma Görevlisi', N'Araştırma İşlemleri yapar', 1)
GO

SET IDENTITY_INSERT [dbo].[KullaniciTipleri] OFF
GO

--
-- Data for table dbo.OgrenciDersler  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[OgrenciDersler] ON
GO

INSERT INTO [dbo].[OgrenciDersler] ([OgrenciDersId], [OgretmenDersId], [OgrenciId], [OgrenciOnayi], [UstOnay], [KayitTarihi], [OnayTarihi])
VALUES 
  (15, 35, 85, 1, 1, '20140602 00:51:33.857', NULL)
GO

INSERT INTO [dbo].[OgrenciDersler] ([OgrenciDersId], [OgretmenDersId], [OgrenciId], [OgrenciOnayi], [UstOnay], [KayitTarihi], [OnayTarihi])
VALUES 
  (16, 35, 88, 1, 1, '20140602 00:51:43.160', NULL)
GO

SET IDENTITY_INSERT [dbo].[OgrenciDersler] OFF
GO

--
-- Data for table dbo.OgrenciSinav  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[OgrenciSinav] ON
GO

INSERT INTO [dbo].[OgrenciSinav] ([OgrenciSinavId], [SinavId], [OgrenciId], [BaslamaZamani], [BitisZamani], [IPNumarasi], [SonGuncellemeTarihi], [ToplamOnlineSure])
VALUES 
  (883, 23, 85, '20140602 01:49:24.877', '20140602 01:52:24.877', NULL, '20140602 01:49:24.877', NULL)
GO

SET IDENTITY_INSERT [dbo].[OgrenciSinav] OFF
GO

--
-- Data for table dbo.OgretmenDersler  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[OgretmenDersler] ON
GO

INSERT INTO [dbo].[OgretmenDersler] ([OgretmenDersId], [OgretmenId], [DersId], [OgretmenOnayi], [UstOnay])
VALUES 
  (35, 84, 27, 1, 1)
GO

SET IDENTITY_INSERT [dbo].[OgretmenDersler] OFF
GO

--
-- Data for table dbo.Sinav  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[Sinav] ON
GO

INSERT INTO [dbo].[Sinav] ([SinavId], [OgretmenDersId], [SinavAdi], [SinavAciklama], [Sure], [BaslangicTarihi], [BitisTarihi], [KayitTrh], [EkleyenId], [UstOnay])
VALUES 
  (23, 35, N'Yazılım Sınavı Test', N'test', 3, '20140601', '20140606', '20140602 01:24:07.710', 84, NULL)
GO

SET IDENTITY_INSERT [dbo].[Sinav] OFF
GO

--
-- Data for table dbo.Sinav_Detay  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[Sinav_Detay] ON
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (1, 8, 4)
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (2, 8, 8)
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (3, 9, 4)
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (4, 9, 8)
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (5, 9, 5)
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (6, 10, 8)
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (7, 10, 7)
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (8, 10, 5)
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (9, 11, 1)
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (10, 11, 2)
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (11, 12, 1)
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (12, 12, 2)
GO

INSERT INTO [dbo].[Sinav_Detay] ([Id], [SinavId], [SorularId])
VALUES 
  (13, 12, 3)
GO

SET IDENTITY_INSERT [dbo].[Sinav_Detay] OFF
GO

--
-- Data for table dbo.SinavDetay  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[SinavDetay] ON
GO

INSERT INTO [dbo].[SinavDetay] ([SinavDetayId], [SinavId], [SoruId])
VALUES 
  (50, 23, 41)
GO

INSERT INTO [dbo].[SinavDetay] ([SinavDetayId], [SinavId], [SoruId])
VALUES 
  (51, 23, 43)
GO

INSERT INTO [dbo].[SinavDetay] ([SinavDetayId], [SinavId], [SoruId])
VALUES 
  (52, 23, 45)
GO

INSERT INTO [dbo].[SinavDetay] ([SinavDetayId], [SinavId], [SoruId])
VALUES 
  (53, 23, 46)
GO

INSERT INTO [dbo].[SinavDetay] ([SinavDetayId], [SinavId], [SoruId])
VALUES 
  (54, 23, 48)
GO

SET IDENTITY_INSERT [dbo].[SinavDetay] OFF
GO

--
-- Data for table dbo.Sorular  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[Sorular] ON
GO

INSERT INTO [dbo].[Sorular] ([SoruId], [OgretmenDersId], [SoruIcerik], [SoruKonu], [SoruResim], [CvpSayisi], [DogruCvp], [Cvp1], [Cvp2], [Cvp3], [Cvp4], [Cvp5], [EkleyenId], [KayitTrh])
VALUES 
  (40, 35, N'Yazılım1', N'Yazılım1', N'', 5, 4, N'Yazılım1', N'Yazılım1', N'Yazılım1', N'Yazılım1', N'Yazılım1', 84, '20140602 00:52:52.963')
GO

INSERT INTO [dbo].[Sorular] ([SoruId], [OgretmenDersId], [SoruIcerik], [SoruKonu], [SoruResim], [CvpSayisi], [DogruCvp], [Cvp1], [Cvp2], [Cvp3], [Cvp4], [Cvp5], [EkleyenId], [KayitTrh])
VALUES 
  (41, 35, N'Yazılım2', N'Yazılım2', N'', 5, 2, N'Yazılım2', N'Yazılım2', N'Yazılım2', N'Yazılım2', N'Yazılım2', 84, '20140602 00:53:10.183')
GO

INSERT INTO [dbo].[Sorular] ([SoruId], [OgretmenDersId], [SoruIcerik], [SoruKonu], [SoruResim], [CvpSayisi], [DogruCvp], [Cvp1], [Cvp2], [Cvp3], [Cvp4], [Cvp5], [EkleyenId], [KayitTrh])
VALUES 
  (42, 35, N'Yazılım3', N'Yazılım3', N'', 5, 4, N'Yazılım3', N'Yazılım3', N'Yazılım3', N'Yazılım3', N'Yazılım3', 84, '20140602 00:53:20.880')
GO

INSERT INTO [dbo].[Sorular] ([SoruId], [OgretmenDersId], [SoruIcerik], [SoruKonu], [SoruResim], [CvpSayisi], [DogruCvp], [Cvp1], [Cvp2], [Cvp3], [Cvp4], [Cvp5], [EkleyenId], [KayitTrh])
VALUES 
  (43, 35, N'Yazılım4', N'Yazılım4', N'', 5, 4, N'Yazılım4', N'Yazılım4', N'Yazılım4', N'Yazılım4', N'Yazılım4', 84, '20140602 00:53:30.257')
GO

INSERT INTO [dbo].[Sorular] ([SoruId], [OgretmenDersId], [SoruIcerik], [SoruKonu], [SoruResim], [CvpSayisi], [DogruCvp], [Cvp1], [Cvp2], [Cvp3], [Cvp4], [Cvp5], [EkleyenId], [KayitTrh])
VALUES 
  (44, 35, N'Yazılım5', N'Yazılım5', N'', 5, 5, N'Yazılım5', N'Yazılım5', N'Yazılım5', N'Yazılım5', N'Yazılım5', 84, '20140602 00:53:41.147')
GO

INSERT INTO [dbo].[Sorular] ([SoruId], [OgretmenDersId], [SoruIcerik], [SoruKonu], [SoruResim], [CvpSayisi], [DogruCvp], [Cvp1], [Cvp2], [Cvp3], [Cvp4], [Cvp5], [EkleyenId], [KayitTrh])
VALUES 
  (45, 35, N'Yazılım6', N'Yazılım6', N'', 5, 3, N'Yazılım6', N'Yazılım6', N'Yazılım6', N'Yazılım6', N'Yazılım6', 84, '20140602 00:53:51.117')
GO

INSERT INTO [dbo].[Sorular] ([SoruId], [OgretmenDersId], [SoruIcerik], [SoruKonu], [SoruResim], [CvpSayisi], [DogruCvp], [Cvp1], [Cvp2], [Cvp3], [Cvp4], [Cvp5], [EkleyenId], [KayitTrh])
VALUES 
  (46, 35, N'Yazılım 8', N'Yazılım 8', N'', 5, 3, N'Yazılım 8', N'Yazılım 8', N'Yazılım 8', N'Yazılım 8', N'Yazılım 8', 84, '20140602 00:54:01.153')
GO

INSERT INTO [dbo].[Sorular] ([SoruId], [OgretmenDersId], [SoruIcerik], [SoruKonu], [SoruResim], [CvpSayisi], [DogruCvp], [Cvp1], [Cvp2], [Cvp3], [Cvp4], [Cvp5], [EkleyenId], [KayitTrh])
VALUES 
  (47, 35, N'Yazılım9', N'Yazılım9', N'', 5, 3, N'Yazılım9', N'Yazılım9', N'Yazılım9', N'Yazılım9', N'Yazılım9', 84, '20140602 00:54:14.507')
GO

INSERT INTO [dbo].[Sorular] ([SoruId], [OgretmenDersId], [SoruIcerik], [SoruKonu], [SoruResim], [CvpSayisi], [DogruCvp], [Cvp1], [Cvp2], [Cvp3], [Cvp4], [Cvp5], [EkleyenId], [KayitTrh])
VALUES 
  (48, 35, N'Yazılım10', N'Yazılım10', N'', 5, 3, N'Yazılım10', N'Yazılım10', N'Yazılım10', N'Yazılım10', N'Yazılım10', 84, '20140602 00:54:30.717')
GO

SET IDENTITY_INSERT [dbo].[Sorular] OFF
GO

--
-- Data for table dbo.sysdiagrams  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[sysdiagrams] ON
GO

INSERT INTO [dbo].[sysdiagrams] ([name], [principal_id], [diagram_id], [version], [definition])
VALUES 
  (N'Diagram_0', 1, 1, 1, 0xD0CF11E0A1B11AE1000000000000000000000000000000003E000300FEFF0900060000000000000000000000010000000100000000000000001000000200000001000000FEFFFFFF0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFF08000000FEFFFFFF0400000005000000060000000700000009000000FEFFFFFF0A0000000B0000000C000000FEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF52006F006F007400200045006E00740072007900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016000500FFFFFFFFFFFFFFFF020000000000000000000000000000000000000000000000000000000000000060E7D1981765CF010300000040110000000000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000201FFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000000000000000000000000000000000000000000016020000000000006F000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040002010100000004000000FFFFFFFF000000000000000000000000000000000000000000000000000000000000000000000000090000001506000000000000010043006F006D0070004F0062006A0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012000201FFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000000000000000000000000000220000005F000000000000000100000002000000030000000400000005000000060000000700000008000000FEFFFFFF0A0000000B0000000C0000000D0000000E0000000F000000100000001100000012000000130000001400000015000000160000001700000018000000190000001A0000001B0000001C0000001D0000001E0000001F0000002000000021000000FEFFFFFF23000000FEFFFFFF25000000260000002700000028000000290000002A0000002B0000002C0000002D0000002E0000002F000000300000003100000032000000330000003400000035000000360000003700000038000000FEFFFFFFFEFFFFFF3B0000003C0000003D0000003E0000003F00000040000000410000004200000043000000FEFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000428000A0E100C05000080040000000F00FFFF04000000007D0000565400005C3C0000E5570000DF3D0000DE805B10F195D011B0A000AA00BDCB5C0000080030000000000200000300000038002B00000009000000D9E6B0E91C81D011AD5100A0C90F5739F43B7F847F61C74385352986E1D552F8A0327DB2D86295428D98273C25A2DA2D00002C0043200000000000000000000053444DD2011FD1118E63006097D2DF4834C9D2777977D811907000065B840D9C00002C0043200000000000000000000051444DD2011FD1118E63006097D2DF4834C9D2777977D811907000065B840D9C04000000280100000084010000003400A50900000700008001000000AA020000008000000C0000805363684772696489D20F00001815000053696E6176536F72756C617200003800A50900000700008002000000AC020000008000000D0000805363684772696489E02E0000C012000053696E617643657661706C617207000000008000A50900000700008003000000520000000180000057000080436F6E74726F6C896D2000006F16000052656C6174696F6E736869702027464B5F53696E617643657661706C61725F53696E6176536F72756C617227206265747765656E202753696E6176536F72756C61722720616E64202753696E617643657661706C6172270000002800B50100000700008004000000310000006D00000002800000436F6E74726F6C899E1F0000B51800000000000000000000000000000000000000000000000000000000000000000000000000000000000000002143341208000000C711000077140000785634120700000014010000530069006E006100760053006F00720075006C006100720000006F006E003D0032002E0030002E0030002E0030002C002000430075006C0074007500720065003D006E00650075007400720061006C002C0020005000750062006C00690063004B006500790054006F006B0065006E003D0062003700370061003500630035003600310039003300340065003000380039000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000005000000540000002C0000002C0000002C00000034000000000000000000000096240000AA1A0000000000002D0100000A0000000C000000070000001C010000BC07000054060000D0020000840300007602000038040000460500002A03000046050000AE060000920400000000000001000000C71100007714000000000000080000000800000002000000020000001C010000CB0700000000000001000000C7110000FF05000000000000010000000100000002000000020000001C010000BC0700000100000000000000C7110000ED03000000000000000000000000000002000000020000001C010000BC0700000000000000000000072C0000DE20000000000000000000000D00000004000000040000001C010000BC07000024090000A005000078563412040000006200000001000000010000000B000000000000000100000002000000030000000400000005000000060000000700000008000000090000000A00000004000000640062006F0000000D000000530069006E006100760053006F00720075006C006100720000002143341208000000C7110000210A0000785634120700000014010000530069006E0061007600430065007600610070006C006100720000006E003D0032002E0030002E0030002E0030002C002000430075006C0074007500720065003D006E00650075007400720061006C002C0020005000750062006C00690063004B006500790054006F006B0065006E003D0062003700370061003500630035003600310039003300340065003000380039000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000005000000540000002C0000002C0000002C0000003400000000000000000000009624000077140000000000002D010000070000000C000000070000001C010000BC07000054060000D0020000840300007602000038040000460500002A03000046050000AE060000920400000000000001000000C7110000210A000000000000030000000300000002000000020000001C010000CB0700000000000001000000C7110000FF05000000000000010000000100000002000000020000001C010000BC0700000100000000000000C7110000ED03000000000000000000000000000002000000020000001C010000BC0700000000000000000000072C0000DE20000000000000000000000D00000004000000040000001C010000BC07000024090000A005000078563412040000006400000001000000010000000B000000000000000100000002000000030000000400000005000000060000000700000008000000090000000A00000004000000640062006F0000000E000000530069006E0061007600430065007600610070006C0061007200000002000B009921000006180000E02E0000061800000000000002000000F0F0F000000000000000000000000000000000000100000004000000000000009E1F0000B51800003C11000058010000320000000100000200003C11000058010000020000000000FFFFFF000800008001000000150001000000900144420100065461686F6D611D0046004B005F00530069006E0061007600430065007600610070006C00610072005F00530069006E006100760053006F00720075006C0061007200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100FEFF030A0000FFFFFFFF00000000000000000000000000000000170000004D6963726F736F66742044445320466F726D20322E300010000000456D626564646564204F626A6563740000000000F439B2710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000C00000000000000000000000100260000007300630068005F006C006100620065006C0073005F00760069007300690062006C0065000000010000000B0000001E000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000010000000100000000000000000000000000000000000000D00200000600280000004100630074006900760065005400610062006C00650056006900650077004D006F006400650000000100000008000400000031000000200000005400610062006C00650056006900650077004D006F00640065003A00300000000100000008003A00000034002C0030002C00320038000300440064007300530074007200650061006D000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000160002000300000006000000FFFFFFFF00000000000000000000000000000000000000000000000000000000000000000000000024000000370500000000000053006300680065006D00610020005500440056002000440065006600610075006C0074000000000000000000000000000000000000000000000000000000000026000200FFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000000000000000000000000000390000001600000000000000440053005200450046002D0053004300480045004D0041002D0043004F004E00540045004E0054005300000000000000000000000000000000000000000000002C0002010500000007000000FFFFFFFF0000000000000000000000000000000000000000000000000000000000000000000000003A000000660200000000000053006300680065006D00610020005500440056002000440065006600610075006C007400200050006F007300740020005600360000000000000000000000000036000200FFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000000000000000000000000000000000000000000044000000120000000000000034002C0030002C0031003900380030002C0031002C0031003600320030002C0035002C0031003000380030000000200000005400610062006C00650056006900650077004D006F00640065003A00310000000100000008001E00000032002C0030002C003200380034002C0030002C0031003900390035000000200000005400610062006C00650056006900650077004D006F00640065003A00320000000100000008001E00000032002C0030002C003200380034002C0030002C0031003900380030000000200000005400610062006C00650056006900650077004D006F00640065003A00330000000100000008001E00000032002C0030002C003200380034002C0030002C0031003900380030000000200000005400610062006C00650056006900650077004D006F00640065003A00340000000100000008003E00000034002C0030002C003200380034002C0030002C0031003900380030002C00310032002C0032003300340030002C00310031002C0031003400340030000000020000000200000000000000000000000000000000000000D00200000600280000004100630074006900760065005400610062006C00650056006900650077004D006F006400650000000100000008000400000031000000200000005400610062006C00650056006900650077004D006F00640065003A00300000000100000008003A00000034002C0030002C003200380034002C0030002C0031003900380030002C0031002C0031003600320030002C0035002C0031003000380030000000200000005400610062006C00650056006900650077004D006F00640065003A00310000000100000008001E00000032002C0030002C003200380034002C0030002C0031003900390035000000200000005400610062006C00650056006900650077004D006F00640065003A00320000000100000008001E00000032002C0030002C003200380034002C0030002C0031003900380030000000200000005400610062006C00650056006900650077004D006F00640065003A00330000000100000008001E00000032002C0030002C003200380034002C0030002C0031003900380030000000200000005400610062006C00650056006900650077004D006F00640065003A00340000000100000008003E00000034002C0030002C003200380034002C0030002C0031003900380030002C00310032002C0032003300340030002C00310031002C00310034003400300000000300000003000000000000004C0000000101CF5001000000640062006F00000046004B005F00530069006E0061007600430065007600610070006C00610072005F00530069006E006100760053006F00720075006C006100720000000000000000000000C40200000000040000000400000003000000080000000138A3120038A3120000000000000000AD0F000001000005000000030000000100000002000000430000004A000000000000000000000000010003000000000000000C0000000B0000004E61BC00000000000000000000000000000000000000000000000000000000000000000000000000000000000000DBE6B0E91C81D011AD5100A0C90F5739000002004099D1981765CF010202000010484500000000000000000000000000000000004C0100004400610074006100200053006F0075007200630065003D002E003B0049006E0069007400690061006C00200043006100740061006C006F0067003D00470041005A0049003B0049006E00740065006700720061007400650064002000530065006300750072006900740079003D0054007200750065003B004D0075006C007400690070006C00650041006300740069007600650052006500730075006C00740053006500740073003D00460061006C00730065003B005000610063006B00650074002000530069007A0065003D0034003000390036003B004100700070006C00690063006100740069006F006E0020004E0061006D0065003D0022004D006900630072006F0073006F00660074002000530051004C00200053006500720076006500720020004D0061006E006100670065006D0065006E0074002000530074007500640069006F002200000000800500140000004400690061006700720061006D005F0030000000000226001A000000530069006E006100760053006F00720075006C0061007200000008000000640062006F000000000224001C000000530069006E0061007600430065007600610070006C0061007200000008000000640062006F00000001000000D68509B3BB6BF2459AB8371664F0327008004E0000007B00310036003300340043004400440037002D0030003800380038002D0034003200450033002D0039004600410032002D004200360044003300320035003600330042003900310044007D0000000000000000000000000000000000000000000000000000000000010003000000000000000C0000000B0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000062885214)
GO

SET IDENTITY_INSERT [dbo].[sysdiagrams] OFF
GO

--
-- Data for table dbo.Temalar  (LIMIT 0,500)
--

SET IDENTITY_INSERT [dbo].[Temalar] ON
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (1, N'a1', N'/Style/Background/Back01.jpg', N'~/Style/Background/thub/thumb_Back01.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (2, N'a2', N'/Style/Background/Back02.jpg', N'~/Style/Background/thub/thumb_Back02.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (3, N'a3', N'/Style/Background/Back03.jpg', N'~/Style/Background/thub/thumb_Back03.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (4, N'a4', N'/Style/Background/Back04.jpg', N'~/Style/Background/thub/thumb_Back04.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (5, N'a5', N'/Style/Background/Back05.jpg', N'~/Style/Background/thub/thumb_Back05.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (6, N'a6', N'/Style/Background/Back06.jpg', N'~/Style/Background/thub/thumb_Back06.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (7, N'a7', N'/Style/Background/Back07.jpg', N'~/Style/Background/thub/thumb_Back07.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (8, N'a8', N'/Style/Background/Back08.jpg', N'~/Style/Background/thub/thumb_Back08.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (9, N'a9', N'/Style/Background/Back09.jpg', N'~/Style/Background/thub/thumb_Back09.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (10, N'a10', N'/Style/Background/Back10.jpg', N'~/Style/Background/thub/thumb_Back10.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (11, N'a11', N'/Style/Background/Back11.jpeg', N'~/Style/Background/thub/thumb_Back11.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (12, N'a12', N'/Style/Background/Back12.jpg', N'~/Style/Background/thub/thumb_Back12.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (13, N'a13', N'/Style/Background/Back13.jpg', N'~/Style/Background/thub/thumb_Back13.png')
GO

INSERT INTO [dbo].[Temalar] ([TemaId], [TemaAdi], [TemaPath], [TemaThumbnailPath])
VALUES 
  (14, N'a14', N'/Style/Background/Back14.jpg', N'~/Style/Background/thub/thumb_Back14.png')
GO

SET IDENTITY_INSERT [dbo].[Temalar] OFF
GO

--
-- Data for table dbo.Test1  (LIMIT 0,500)
--

INSERT INTO [dbo].[Test1] ([Kolon1], [Kolon2], [Kolon3], [Kolon4])
VALUES 
  (N'a', N'b', N'c', N'd')
GO

INSERT INTO [dbo].[Test1] ([Kolon1], [Kolon2], [Kolon3], [Kolon4])
VALUES 
  (N'a', N'b', N'c', N'd')
GO

--
-- Data for table dbo.Test2  (LIMIT 0,500)
--

INSERT INTO [dbo].[Test2] ([Kolon1])
VALUES 
  (N'c')
GO

INSERT INTO [dbo].[Test2] ([Kolon1])
VALUES 
  (N'c')
GO

--
-- Data for table dbo.Test3  (LIMIT 0,500)
--

INSERT INTO [dbo].[Test3] ([Kolon1])
VALUES 
  (N'b')
GO

INSERT INTO [dbo].[Test3] ([Kolon1])
VALUES 
  (N'b')
GO

--
-- Data for table dbo.Test4  (LIMIT 0,500)
--

INSERT INTO [dbo].[Test4] ([Kolon1])
VALUES 
  (N'a')
GO

INSERT INTO [dbo].[Test4] ([Kolon1])
VALUES 
  (N'a')
GO

--
-- Definition for indices : 
--

ALTER TABLE [dbo].[DersIcerikler]
ADD CONSTRAINT [PK_DersIcerikler] 
PRIMARY KEY CLUSTERED ([IcerikId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[Dersler]
ADD CONSTRAINT [PK_Dersler] 
PRIMARY KEY CLUSTERED ([DersId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[Duyurular]
ADD CONSTRAINT [PK_Duyurular] 
PRIMARY KEY CLUSTERED ([DuyuruId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[DuyuruKullanicilar]
ADD CONSTRAINT [PK_DuyuruKullanicilar] 
PRIMARY KEY CLUSTERED ([Id])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[Formlar]
ADD CONSTRAINT [PK_Formlar] 
PRIMARY KEY CLUSTERED ([Id])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[HareketTipleri]
ADD CONSTRAINT [PK_HareketTipleri] 
PRIMARY KEY CLUSTERED ([HareketId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[Il]
ADD CONSTRAINT [PK_Il] 
PRIMARY KEY CLUSTERED ([IlKodu])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[Ilce]
ADD CONSTRAINT [pk_Ilce_ilceKodu] 
PRIMARY KEY CLUSTERED ([IlceKodu])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[KullaniciDersler]
ADD CONSTRAINT [PK_KullaniciDersler] 
PRIMARY KEY CLUSTERED ([Id])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[KullaniciFormlar]
ADD CONSTRAINT [PK_KullaniciFormlar] 
PRIMARY KEY CLUSTERED ([Id])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[Kullanicilar]
ADD CONSTRAINT [PK_Kullanicilar] 
PRIMARY KEY CLUSTERED ([KullaniciId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[KullaniciLogAna]
ADD CONSTRAINT [PK_KullaniciLogAna] 
PRIMARY KEY CLUSTERED ([Id])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[KullaniciLogDetail]
ADD CONSTRAINT [PK_KullaniciLogDetail] 
PRIMARY KEY CLUSTERED ([Id])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[KullaniciTipleri]
ADD CONSTRAINT [PK_KullaniciTipleri] 
PRIMARY KEY CLUSTERED ([KullaniciTipId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[Ogr_Sinav]
ADD CONSTRAINT [PK_Ogr_Sinav] 
PRIMARY KEY CLUSTERED ([Id])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[OgrenciDersler]
ADD CONSTRAINT [PK_OgrenciDers] 
PRIMARY KEY CLUSTERED ([OgrenciDersId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[OgrenciSinav]
ADD CONSTRAINT [PK_OgrenciSinav] 
PRIMARY KEY CLUSTERED ([OgrenciSinavId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[OgrenciSinavDetay]
ADD CONSTRAINT [PK_OgrenciSinavDetay] 
PRIMARY KEY CLUSTERED ([OgrenciSinavDetayId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[OgretmenDersler]
ADD CONSTRAINT [PK_OgretmenDers] 
PRIMARY KEY CLUSTERED ([OgretmenDersId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[Sinav]
ADD CONSTRAINT [PK_Sinav] 
PRIMARY KEY CLUSTERED ([SinavId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[Sinav_Detay]
ADD CONSTRAINT [PK_Sinav_Detay_1] 
PRIMARY KEY CLUSTERED ([Id])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[SinavDetay]
ADD CONSTRAINT [PK_SinavDetay] 
PRIMARY KEY CLUSTERED ([SinavDetayId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[Sorular]
ADD CONSTRAINT [PK_Sorular] 
PRIMARY KEY CLUSTERED ([SoruId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[sysdiagrams]
ADD CONSTRAINT [PK__sysdiagr__C2B05B615629CD9C] 
PRIMARY KEY CLUSTERED ([diagram_id])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO

ALTER TABLE [dbo].[sysdiagrams]
ADD CONSTRAINT [UK_principal_name] 
UNIQUE NONCLUSTERED ([principal_id], [name])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



ALTER TABLE [dbo].[Temalar]
ADD CONSTRAINT [PK_Temalar] 
PRIMARY KEY CLUSTERED ([TemaId])
WITH (
  PAD_INDEX = OFF,
  IGNORE_DUP_KEY = OFF,
  STATISTICS_NORECOMPUTE = OFF,
  ALLOW_ROW_LOCKS = ON,
  ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO



--
-- Definition for foreign keys : 
--

ALTER TABLE [dbo].[DuyuruKullanicilar]
ADD CONSTRAINT [FK_DuyuruKullanicilar_Duyurular] FOREIGN KEY ([DuyuruId]) 
  REFERENCES [dbo].[Duyurular] ([DuyuruId]) 
  ON UPDATE NO ACTION
  ON DELETE NO ACTION
GO



