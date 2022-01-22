using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class Il
    {
        [Key]
        public int IlKodu { get; set; }
        public string IlAdi { get; set; }
    }
}