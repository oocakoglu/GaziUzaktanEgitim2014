using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class DuyuruKullanicilar
    {
        [Key]
        public int Id { get; set; }
        public int? DuyuruId { get; set; }
        public int? KullaniciTipiId { get; set; }
        public virtual Duyurular Duyurular { get; set; }
    }
}