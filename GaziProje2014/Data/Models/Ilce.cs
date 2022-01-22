using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class Ilce
    {
        [Key]
        public int IlceKodu { get; set; }
        public string IlceAdi { get; set; }
        public int? IlKodu { get; set; }
        public string IlAdi { get; set; }
        public string IegmIlceKodu { get; set; }
        public string IlceSon { get; set; }
    }
}