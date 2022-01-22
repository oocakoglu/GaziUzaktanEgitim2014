using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class HareketTipi
    {
        [Key]
        public int HareketId { get; set; }
        public string HareketAdi { get; set; }
    }
}