using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class Temalar
    {
        [Key]
        public int TemaId { get; set; }
        public string TemaAdi { get; set; }
        public string TemaPath { get; set; }
        public string TemaThumbnailPath { get; set; }
        
    }
}