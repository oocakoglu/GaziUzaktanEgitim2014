using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class DersIcerikler
    {
        [Key]
        public int IcerikId { get; set; }
        public int? IcerikPId { get; set; }
        public int? OgretmenDersId { get; set; }
        public string IcerikAdi { get; set; }
        public int? IcerikTip { get; set; }
        public string IcerikText { get; set; }
        public string IcerikUrl { get; set; }
        public int? DersSira { get; set; }
        public string IconUrl { get; set; }
        public int? EkleyenId { get; set; }
        public DateTime? KayitTarihi { get; set; }
        public bool? GenelIcerik { get; set; }
        public string UrlName { get; set; }
        public string ThumbnailPath { get; set; }
        public int? VideoSaniye { get; set; }
        public string UrlAciklama { get; set; }
    }
}