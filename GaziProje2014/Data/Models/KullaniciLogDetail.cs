using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class KullaniciLogDetail
    {
        [Key]
        public int Id { get; set; }
        public int? KullaniciId { get; set; }
        public int? HareketId { get; set; }
        public DateTime? HareketTarihi { get; set; }
        public string IpNumarasi { get; set; }
    }
}