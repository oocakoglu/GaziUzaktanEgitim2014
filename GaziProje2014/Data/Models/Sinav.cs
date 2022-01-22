using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class Sinav
    {
        [Key]
        public int SinavId { get; set; }
        public int? OgretmenDersId { get; set; }
        public string SinavAdi { get; set; }
        public string SinavAciklama { get; set; }
        public int? Sure { get; set; }
        public DateTime? BaslangicTarihi { get; set; }
        public DateTime? BitisTarihi { get; set; }
        public DateTime? KayitTrh { get; set; }
        public int? EkleyenId { get; set; }
        public bool? UstOnay { get; set; }
    }
}