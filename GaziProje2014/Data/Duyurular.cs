//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace GaziProje2014.Data
{
    using System;
    using System.Collections.Generic;
    
    public partial class Duyurular
    {
        public Duyurular()
        {
            this.DuyuruKullanicilar = new HashSet<DuyuruKullanicilar>();
        }
    
        public int DuyuruId { get; set; }
        public string DuyuruAdi { get; set; }
        public string DuyuruIcerik { get; set; }
        public Nullable<System.DateTime> DuyuruTarihi { get; set; }
        public Nullable<int> DuyuruKayitEdenId { get; set; }
    
        public virtual ICollection<DuyuruKullanicilar> DuyuruKullanicilar { get; set; }
    }
}