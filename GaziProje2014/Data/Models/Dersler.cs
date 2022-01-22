using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class Dersler
    {
        [Key]
        public int DersId { get; set; }
        public string DersAdi { get; set; }
        public string DersAciklama { get; set; }
        public bool? DersDurum { get; set; }
    }
}