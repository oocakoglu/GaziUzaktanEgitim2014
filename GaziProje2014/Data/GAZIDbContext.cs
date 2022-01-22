using GaziProje2014.Data.Models;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.Entity.ModelConfiguration.Conventions;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data
{
    public class GAZIDbContext : DbContext
    {
        //protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        //{
        //    optionsBuilder.UseSqlServer(@"Server=.;Database=SipDB;Trusted_Connection=True;");
        //}
        //public GAZIDbContext()
        //    : base("name=GAZIDbContext")
        //{
        //}
        public GAZIDbContext()
            : base("Server=.;Database=GAZI;Trusted_Connection=True;")
        {
        }
        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            //**Plural Named Disabled
            modelBuilder.Conventions.Remove<PluralizingTableNameConvention>();
            base.OnModelCreating(modelBuilder);
        }

        public DbSet<GaziProje2014.Data.Models.DersIcerikler> DersIcerikler { get; set; }
        public DbSet<GaziProje2014.Data.Models.Dersler> Dersler { get; set; }
        public DbSet<GaziProje2014.Data.Models.DuyuruKullanicilar> DuyuruKullanicilar { get; set; }
        public DbSet<GaziProje2014.Data.Models.Duyurular> Duyurular { get; set; }
        public DbSet<GaziProje2014.Data.Models.Formlar> Formlar { get; set; }
        public DbSet<GaziProje2014.Data.Models.HareketTipi> HareketTipleri { get; set; }
        public DbSet<GaziProje2014.Data.Models.Il> Il { get; set; }
        public DbSet<GaziProje2014.Data.Models.Ilce> Ilce { get; set; }
        public DbSet<GaziProje2014.Data.Models.KullaniciFormlar> KullaniciFormlar { get; set; }
        public DbSet<GaziProje2014.Data.Models.Kullanicilar> Kullanicilar { get; set; }
        public DbSet<GaziProje2014.Data.Models.KullaniciLogAna> KullaniciLogAna { get; set; }
        public DbSet<GaziProje2014.Data.Models.KullaniciLogDetail> KullaniciLogDetail { get; set; }
        public DbSet<GaziProje2014.Data.Models.KullaniciTipleri> KullaniciTipleri { get; set; }
        public DbSet<GaziProje2014.Data.Models.OgrenciDersler> OgrenciDersler { get; set; }
        public DbSet<GaziProje2014.Data.Models.OgrenciSinav> OgrenciSinav { get; set; }
        public DbSet<GaziProje2014.Data.Models.OgrenciSinavDetay> OgrenciSinavDetay { get; set; }
        public DbSet<GaziProje2014.Data.Models.OgretmenDersler> OgretmenDersler { get; set; }
        public DbSet<GaziProje2014.Data.Models.Sinav> Sinav { get; set; }
        public DbSet<GaziProje2014.Data.Models.SinavDetay> SinavDetay { get; set; }
        public DbSet<GaziProje2014.Data.Models.Sorular> Sorular { get; set; }
        public DbSet<GaziProje2014.Data.Models.Temalar> Temalar { get; set; }
    }
}