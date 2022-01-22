using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data.Models
{
    public class Duyurular
    {
        public Duyurular()
        {
            this.DuyuruKullanicilar = new HashSet<DuyuruKullanicilar>();
        }

        [Key]
        public int DuyuruId { get; set; }
        public string DuyuruAdi { get; set; }
        public string DuyuruIcerik { get; set; }
        public DateTime? DuyuruTarihi { get; set; }
        public int? DuyuruKayitEdenId { get; set; }

        public virtual ICollection<DuyuruKullanicilar> DuyuruKullanicilar { get; set; }
    }
}