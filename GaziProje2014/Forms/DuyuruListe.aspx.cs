using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;

namespace GaziProje2014.Forms
{
    public partial class DuyuruListe : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                GAZIEntities gaziEntities = new GAZIEntities();           
                var duyurular = (from d in gaziEntities.Duyurular
                                 join k in gaziEntities.Kullanicilar on d.DuyuruKayitEdenId equals k.KullaniciId
                                 select new { d.DuyuruId, d.DuyuruAdi, d.DuyuruTarihi, k.KullaniciId, k.Adi, k.Soyadi }).Take(100).ToList();
                RadGrid1.DataSource = duyurular;
                RadGrid1.DataBind();
            }
        }
        protected void btnDuyuruListeSorgula_Click(object sender, EventArgs e)
        {
            GAZIEntities gaziEntities = new GAZIEntities();
            var duyurular = (from d in gaziEntities.Duyurular
                             join k in gaziEntities.Kullanicilar on d.DuyuruKayitEdenId equals k.KullaniciId
                             select new { d.DuyuruId, d.DuyuruAdi, d.DuyuruTarihi, k.KullaniciId, k.Adi, k.Soyadi });

            if (dteBaslangicTarihi.SelectedDate != null)
                duyurular = duyurular.Where(x => x.DuyuruTarihi >= dteBaslangicTarihi.SelectedDate);

            if (dteBitisTarihi.SelectedDate != null)
                duyurular = duyurular.Where(x => x.DuyuruTarihi <= dteBitisTarihi.SelectedDate);

            if (txtDuyuruAdi.Text != "")
                duyurular = duyurular.Where(x => x.DuyuruAdi.StartsWith(txtDuyuruAdi.Text));

            RadGrid1.DataSource = duyurular.Take(100).ToList();
            RadGrid1.DataBind();
        }
        protected void btnDuzenle_Click(object sender, EventArgs e)
        {
            if (RadGrid1.SelectedItems.Count > 0)
            {
                string DuyuruId = RadGrid1.SelectedValues["DuyuruId"].ToString();
                Response.Redirect("DuyuruDetay.aspx?DuyuruId=" + DuyuruId);
            }
        }
        protected void btnYeniEkle_Click(object sender, EventArgs e)
        {   
            Response.Redirect("DuyuruDetay.aspx");       
        }
        protected void btnSil_Click(object sender, EventArgs e)
        { 
            if (RadGrid1.SelectedValues["DuyuruId"].ToString() != "")
            {
                GAZIEntities gaziEntities = new GAZIEntities();
                int duyuruId = Convert.ToInt32(RadGrid1.SelectedValues["DuyuruId"].ToString());

                //** Önceki Kayıtkarı Temizle
                var duyuruKullanicilar = (from d in gaziEntities.DuyuruKullanicilar
                                          where d.DuyuruId == duyuruId
                                          select d).ToList();

                foreach (var item in duyuruKullanicilar)
                {
                    gaziEntities.DuyuruKullanicilar.Remove(item);
                }
                Duyurular duyurular = gaziEntities.Duyurular.Where(q => q.DuyuruId == duyuruId).FirstOrDefault();
                gaziEntities.Duyurular.Remove(duyurular);
                gaziEntities.SaveChanges();
                Session["Mesaj"] = "Duyuru Sistemden Başarıyla Silinmiştir";
                btnDuyuruListeSorgula_Click(null ,null);
            }
        }
    }
}