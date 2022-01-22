using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class OgrenciSinavDetay
    {
        [Key]
        public int OgrenciSinavDetayId { get; set; }
        public int? OgrenciSinavId { get; set; }
        public int? SoruId { get; set; }
        public int? OgrenciCvp { get; set; }
    }
}