using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public  class Formlar
    {
        [Key]
        public int Id { get; set; }
        public int? PId { get; set; }
        public string PFormBaslik { get; set; }
        public string FormBaslik { get; set; }
        public string FormAdi { get; set; }
        public string FormAciklama { get; set; }
        public string FormImageUrl { get; set; }
    }
}