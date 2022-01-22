using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class SinavDetay
    {
        [Key]
        public int SinavDetayId { get; set; }
        public int? SinavId { get; set; }
        public int? SoruId { get; set; }
    }
}