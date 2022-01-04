<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="KullaniciListesi.aspx.cs" Inherits="GaziProje2014.Forms.KullaniciListesi" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

        
        <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">
            <script type="text/javascript">
                function ShowEditForm(id, rowIndex) {
                    var grid = $find("<%= RadGrid1.ClientID %>");

                    var rowControl = grid.get_masterTableView().get_dataItems()[rowIndex].get_element();
                    grid.get_masterTableView().selectItem(rowControl, true);

                    window.radopen("KullaniciDetay.aspx?KullaniciId=" + id, "UserListDialog");
                    return false;
                }
                function ShowInsertForm() {
                    window.radopen("KullaniciDetay.aspx", "UserListDialog");
                    return false;
                }
                function refreshGrid(arg) {
                    if (!arg) {
                        $find("<%= RadAjaxManager1.ClientID %>").ajaxRequest("Rebind");
                    }
                    else {
                        $find("<%= RadAjaxManager1.ClientID %>").ajaxRequest("RebindAndNavigate");
                    }
                }
                function RowDblClick(sender, eventArgs) {
                    //alert("EditFormCS.aspx?KullaniciId=" + eventArgs.getDataKeyValue("KullaniciId"));
                    // window.radopen("EditFormCS.aspx?KullaniciId=" + eventArgs.getDataKeyValue("KullaniciId"), "UserListDialog");
                    window.radopen("KullaniciDetay.aspx?KullaniciId=" + eventArgs.getDataKeyValue("KullaniciId"), "UserListDialog");
                }
            </script>
        </telerik:RadCodeBlock>
    
        <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server" OnAjaxRequest="RadAjaxManager1_AjaxRequest">
            <AjaxSettings>
                <telerik:AjaxSetting AjaxControlID="RadAjaxManager1">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="gridLoadingPanel"></telerik:AjaxUpdatedControl>
                    </UpdatedControls>
                </telerik:AjaxSetting>
                <telerik:AjaxSetting AjaxControlID="RadGrid1">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="gridLoadingPanel"></telerik:AjaxUpdatedControl>
                    </UpdatedControls>
                </telerik:AjaxSetting>
            </AjaxSettings>
        </telerik:RadAjaxManager>


    <div class="contentUst40">
           <table class="tdTablo">
                <tr>
                    <td class="tdCellBaslik">Kullanıcı Tipi :</td>
                    <td class="tdCellIcerik"><telerik:RadTextBox ID="txtKullaniciTipi" runat="server"></telerik:RadTextBox></td>
                    <td class="tdCellBaslik">Adı :</td>
                    <td class="tdCellIcerik"><telerik:RadTextBox ID="txtAdi" runat="server"></telerik:RadTextBox></td>       
                    <td class="tdCellBaslik">Soyadı :</td>
                    <td class="tdCellIcerik"><telerik:RadTextBox ID="txtSoyadi" runat="server"></telerik:RadTextBox></td> 
                    <td class="tdCellBaslik">  
                    <telerik:RadButton ID="RadButton1" runat="server" Text="Sorgula" OnClick="RadButton1_Click1">
                    </telerik:RadButton> 
                    </td>                                                           
                </tr>
            </table>
    </div>
    <div class="contentUst40Golge">
    </div>

    <div class="contentOrta40x40">    
        <telerik:RadGrid ID="RadGrid1" runat="server"   DataSourceID="SqlDataSource1" >
      
        <ClientSettings EnableRowHoverStyle="true">
            <Selecting AllowRowSelect="True" />
            <ClientEvents OnRowDblClick="RowDblClick"></ClientEvents>
        </ClientSettings>



            <MasterTableView AutoGenerateColumns="False" DataKeyNames="KullaniciId" ClientDataKeyNames="KullaniciId" 
                DataSourceID="SqlDataSource1">
                <Columns>

            <telerik:GridImageColumn DataImageUrlFields="Resim" DataImageUrlFormatString="{0}" 
                HeaderText="Resim" ImageHeight="60px" ImageWidth="45px" UniqueName="cmlResim" HeaderStyle-Width ="100px">
            </telerik:GridImageColumn>

                <telerik:GridTemplateColumn HeaderText="Description" UniqueName="Description" DataField="Description"  HeaderStyle-Width ="180px">
                <ItemTemplate>
                    <asp:Label Text='<%# Bind("KullaniciTipAdi") %>' runat="server" ID="lblKullaniciTipAdi" />
                    <br>                                          
                    <asp:Label Text='<%# Bind("Adi") %>' runat="server" ID="lblAdi" />
                    <br>
                    <asp:Label Text='<%# Bind("Soyadi") %>' runat="server" ID="lblSoyadi" />                                          
                </ItemTemplate>
                </telerik:GridTemplateColumn>

                <telerik:GridTemplateColumn HeaderText="Description" UniqueName="Description" DataField="Description"  HeaderStyle-Width ="180px">
                <ItemTemplate>
                    Cep : <asp:Label Text='<%# Bind("CepTel") %>' runat="server" ID="lblCepTel" />
                    <br>
                    Ev : <asp:Label Text='<%# Bind("EvTel") %>' runat="server" ID="lblEvTel" /> 
                        <br>                                     
                    Email : <asp:Label Text='<%# Bind("Email") %>' runat="server" ID="lblemail" />                                          
                </ItemTemplate>
                </telerik:GridTemplateColumn>

                <telerik:GridTemplateColumn HeaderText="Description" UniqueName="Description" DataField="Description"  HeaderStyle-Width ="180px">
                    <ItemTemplate>
                        <asp:Label Text='<%# Bind("IlAdi") %>' runat="server" ID="lblIlAdi" />
                        <br>                                          
                        <asp:Label Text='<%# Bind("IlceAdi") %>' runat="server" ID="lblIlceAdi" />
                        <br>                                    
                    </ItemTemplate>
                </telerik:GridTemplateColumn>

                    <telerik:GridBoundColumn DataField="Adres" 
                        FilterControlAltText="Filter Adres column" HeaderText="Adres" 
                        SortExpression="Adres" UniqueName="Adres">
                    </telerik:GridBoundColumn>
     
                    <telerik:GridCheckBoxColumn DataField="Onay" DataType="System.Boolean" 
                        FilterControlAltText="Filter Onay column" HeaderText="Onay" 
                        SortExpression="Onay" UniqueName="Onay">
                    </telerik:GridCheckBoxColumn>
            
                </Columns>
            </MasterTableView>
        </telerik:RadGrid>
    </div>    
    
    <div class="contentAlt30">
        <telerik:RadButton Width="100px" ID="btnYeniEkle" runat="server" Text="Yeni Ekle" OnClientClicked="ShowInsertForm" AutoPostBack="false"></telerik:RadButton>         
        <telerik:RadButton Width="100px" ID="btnDuzenle" runat="server" Text="Düzenle"  OnClientClicking="RowDblClick" AutoPostBack="false"></telerik:RadButton>         
        <telerik:RadButton Width="100px" ID="btnSil" runat="server" Text="Sil" OnClick="btnSil_Click"></telerik:RadButton>
    </div>    
    <div class="contentAlt30Golge"> 
    </div>

    <telerik:RadWindowManager ID="RadWindowManager1" runat="server" EnableShadow="true">
        <Windows>
            <telerik:RadWindow ID="UserListDialog" runat="server" Title="Editing record" Height="570px"
                Width="600px"  ReloadOnShow="true" ShowContentDuringLoad="false"
                Modal="true" >
            </telerik:RadWindow>
        </Windows>
    </telerik:RadWindowManager>

    <asp:SqlDataSource ID="SqlDataSource1" runat="server" 
        ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" 
        SelectCommand="Select K.KullaniciId, K.KullaniciAdi, K.KullaniciSifre, K.Adi, K.Soyadi,
                        KT.KullaniciTipAdi, K.DogumTarihi, K.Cinsiyet, K.CepTel, K.EvTel, 
                        K.Email, K.IlKodu, K.IlceKodu, K.Adres, K.Resim, K.KayitTarihi, 
                        K.Onay, I1.IlAdi, I2.IlceAdi From Kullanicilar K
                        Left Join Il I1 ON K.IlKodu = I1.IlKodu
                        Left Join Ilce I2 ON K.IlceKodu = I2.IlceKodu
                        Left Join KullaniciTipleri KT ON KT.KullaniciTipId = K.KullaniciTipi
                        ORDER BY K.KullaniciId"></asp:SqlDataSource>

</asp:Content>
