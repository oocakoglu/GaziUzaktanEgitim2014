using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using GaziProje2014.Data.Models;
using Telerik.Web.UI;

namespace GaziProje2014.Forms
{
    public partial class OgrenciDersSecim : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                grdOnayBekleyenDerslerBind();
            }
        }

        protected void btnSorgula_Click(object sender, EventArgs e)
        {
            grdOnayBekleyenDerslerBind();
        }

        protected void btnOgrenciDersSec_Click(object sender, EventArgs e)
        {
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            GAZIDbContext gaziEntities = new GAZIDbContext();

            foreach (GridDataItem item in grdOgrenciDersSecim.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["chkTemplateColumn"].FindControl("chkOgrenciOnay");
                if (chk.Checked)
                {
                    int ogretmenDersId = Convert.ToInt32(item["OgretmenDersId"].Text);

                    OgrenciDersler ogrenciDersler = new OgrenciDersler();
                    ogrenciDersler.OgretmenDersId = ogretmenDersId;
                    ogrenciDersler.OgrenciId = kullaniciId;
                    ogrenciDersler.OgrenciOnayi = true;
                    ogrenciDersler.KayitTarihi = DateTime.Now;
                    gaziEntities.OgrenciDersler.Add(ogrenciDersler);
                    gaziEntities.SaveChanges();
                }
            }
            gaziEntities.SaveChanges();
            grdOnayBekleyenDerslerBind();
        }

        private void grdOnayBekleyenDerslerBind()
        {
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            GAZIDbContext gaziEntities = new GAZIDbContext();

            //** Ogrencinin daha önce seçtiği dersler
            var ogretmenDersIds = from ogtd in gaziEntities.OgrenciDersler
                                  where ogtd.OgrenciId == kullaniciId
                                  select ogtd.OgretmenDersId;

            var dersSecimListesi = (from od in gaziEntities.OgretmenDersler
                                    join d in gaziEntities.Dersler on od.DersId equals d.DersId
                                    join k in gaziEntities.Kullanicilar on od.OgretmenId equals k.KullaniciId
                                    where od.UstOnay == true && !ogretmenDersIds.Contains(od.OgretmenDersId)                           
                                    select new { od.OgretmenDersId, d.DersAdi, d.DersAciklama, DersiVeren = k.Adi + " " + k.Soyadi });

            if (txtDersAdi.Text != "")
                dersSecimListesi = dersSecimListesi.Where(q => q.DersAdi.StartsWith(txtDersAdi.Text));

            if (txtOgretmenAdi.Text != "")
                dersSecimListesi = dersSecimListesi.Where(q => q.DersiVeren.StartsWith(txtOgretmenAdi.Text));


            grdOgrenciDersSecim.DataSource = dersSecimListesi.Take(200).OrderBy(q => q.DersAdi).ToList();
            grdOgrenciDersSecim.DataBind();
        }
    }
}