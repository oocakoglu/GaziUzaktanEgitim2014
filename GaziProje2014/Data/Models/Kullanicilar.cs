using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class Kullanicilar
    {
        [Key]
        public int KullaniciId { get; set; }
        public string KullaniciAdi { get; set; }
        public string KullaniciSifre { get; set; }
        public string Adi { get; set; }
        public string Soyadi { get; set; }
        public int? KullaniciTipi { get; set; }
        public DateTime? DogumTarihi { get; set; }
        public int? Cinsiyet { get; set; }
        public string CepTel { get; set; }
        public string EvTel { get; set; }
        public string Email { get; set; }
        public int? IlKodu { get; set; }
        public int? IlceKodu { get; set; }
        public string Adres { get; set; }
        public string Resim { get; set; }
        public DateTime? KayitTarihi { get; set; }
        public bool? Onay { get; set; }
        public string DokumanAdres { get; set; }
        public string SkinName { get; set; }
        public string BackGround { get; set; }
    }
}