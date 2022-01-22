using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class KullaniciTipleri
    {
        [Key]
        public int KullaniciTipId { get; set; }
        public string KullaniciTipAdi { get; set; }
        public string KullaniciTipAciklama { get; set; }
        public bool? KullaniciTipDurum { get; set; }
    }
}