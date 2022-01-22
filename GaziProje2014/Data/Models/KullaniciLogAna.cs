using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class KullaniciLogAna
    {
        [Key]
        public int Id { get; set; }
        public int? KullaniciId { get; set; }
        public TimeSpan? ToplamSure { get; set; }
    }
}