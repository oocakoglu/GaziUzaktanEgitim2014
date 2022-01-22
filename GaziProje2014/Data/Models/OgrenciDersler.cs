using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class OgrenciDersler
    {
        [Key]
        public int OgrenciDersId { get; set; }
        public int? OgretmenDersId { get; set; }
        public int? OgrenciId { get; set; }
        public bool? OgrenciOnayi { get; set; }
        public bool? UstOnay { get; set; }
        public DateTime? KayitTarihi { get; set; }
        public DateTime? OnayTarihi { get; set; }
    }
}