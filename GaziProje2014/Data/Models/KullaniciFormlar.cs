using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class KullaniciFormlar
    {
        [Key]
        public int Id { get; set; }
        public int? KullaniciTipiId { get; set; }
        public int? FormId { get; set; }
        public bool? FormYetki { get; set; }
    }
}