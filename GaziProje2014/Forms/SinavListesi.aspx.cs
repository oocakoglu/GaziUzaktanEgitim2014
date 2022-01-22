using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;

namespace GaziProje2014.Forms
{
    public partial class SinavListesi : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                grdSinavlarBind();
            }
        }

        protected void btnSorgula_Click(object sender, EventArgs e)
        {
            grdSinavlarBind();
        }
        
        private void grdSinavlarBind()
        {
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            int kullaniciTipiId = Convert.ToInt32(Session["KullaniciTipiId"].ToString());

            GAZIDbContext gaziEntities = new GAZIDbContext();
            var sinavListesi = (from s  in gaziEntities.Sinav
                                from od in gaziEntities.OgretmenDersler.Where(q => q.OgretmenDersId == s.OgretmenDersId).DefaultIfEmpty()
                                from d in gaziEntities.Dersler.Where(q => q.DersId == od.DersId).DefaultIfEmpty() 

                                //join od in gaziEntities.OgretmenDersler on s.OgretmenDersId equals od.OgretmenDersId
                                //join d in gaziEntities.Dersler on od.DersId equals d.DersId
                                select new { s.SinavId, s.EkleyenId, d.DersAdi, s.SinavAdi, s.SinavAciklama, s.BaslangicTarihi, s.BitisTarihi });


            if (txtDersAdi.Text != "")
                sinavListesi = sinavListesi.Where(q => q.DersAdi.StartsWith(txtDersAdi.Text));

            if (txtSinavAdi.Text != "")
                sinavListesi = sinavListesi.Where(q => q.SinavAdi.StartsWith(txtSinavAdi.Text));


            if (kullaniciTipiId != 1)
            {
                sinavListesi = sinavListesi.Where(q => q.EkleyenId == kullaniciId);
            }

            //grdSinavlar.DataSource = sinavListesi.Take(200).OrderBy(q => q.DersAdi).ToList();
            grdSinavlar.DataSource = sinavListesi.Take(200).ToList();
            grdSinavlar.DataBind();
        }

        protected void btnSinavDuzenle_Click(object sender, EventArgs e)
        {
            if (grdSinavlar.SelectedItems.Count > 0)
            {
                string sinavId = grdSinavlar.SelectedValues["SinavId"].ToString();
                Session.Add("SinavId", sinavId);
                Response.Redirect("~/Forms/SinavDetay.aspx");
            }
        }

        protected void btnSinavEkle_Click(object sender, EventArgs e)
        {
            Response.Redirect("~/Forms/SinavDetay.aspx");
        }

        protected void btnSinavSil_Click(object sender, EventArgs e)
        {
            if (grdSinavlar.SelectedItems.Count > 0)
            {
                int sinavId = Convert.ToInt32(grdSinavlar.SelectedValues["SinavId"].ToString());
                GAZIDbContext gaziEntities = new GAZIDbContext();
                Data.Models.Sinav sinav = gaziEntities.Sinav.Where(q => q.SinavId == sinavId).FirstOrDefault();                
                gaziEntities.Sinav.Remove(sinav);
                gaziEntities.SaveChanges();
                grdSinavlarBind();
            }
        }
        

    }
}