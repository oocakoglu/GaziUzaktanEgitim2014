using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class OgrenciSinav
    {
        [Key]
        public int OgrenciSinavId { get; set; }
        public int? SinavId { get; set; }
        public int? OgrenciId { get; set; }
        public DateTime? BaslamaZamani { get; set; }
        public DateTime? BitisZamani { get; set; }
        public string IPNumarasi { get; set; }
        public DateTime? SonGuncellemeTarihi { get; set; }
        public int? ToplamOnlineSure { get; set; }
    }
}