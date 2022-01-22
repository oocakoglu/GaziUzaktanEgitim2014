using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class Sorular
    {
        [Key]
        public int SoruId { get; set; }
        public int? OgretmenDersId { get; set; }
        public string SoruIcerik { get; set; }
        public string SoruKonu { get; set; }
        public string SoruResim { get; set; }
        public int? CvpSayisi { get; set; }
        public int? DogruCvp { get; set; }
        public string Cvp1 { get; set; }
        public string Cvp2 { get; set; }
        public string Cvp3 { get; set; }
        public string Cvp4 { get; set; }
        public string Cvp5 { get; set; }
        public int? EkleyenId { get; set; }
        public DateTime? KayitTrh { get; set; }
    }
}