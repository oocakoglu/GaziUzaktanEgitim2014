using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class OgretmenDersler
    {
        [Key]
        public int OgretmenDersId { get; set; }
        public int? OgretmenId { get; set; }
        public int? DersId { get; set; }
        public bool? OgretmenOnayi { get; set; }
        public bool? UstOnay { get; set; }
    }
}