using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;

namespace GaziProje2014.Forms
{
    public partial class OgrenciSinavListesi : System.Web.UI.Page
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
           
            GAZIDbContext gaziEntities = new GAZIDbContext();
            var sinavListesi = (from s in gaziEntities.Sinav 
                                where s.BaslangicTarihi <= DateTime.Now && s.BitisTarihi >= DateTime.Now
                                from grlsnv in gaziEntities.OgrenciSinav.Where(q => q.SinavId == s.SinavId && q.OgrenciId == kullaniciId).DefaultIfEmpty()
                                where (grlsnv.SinavId == null || grlsnv.BitisZamani > DateTime.Now)
                                from od in gaziEntities.OgretmenDersler.Where(q => q.OgretmenDersId == s.OgretmenDersId).DefaultIfEmpty()
                                from d in gaziEntities.Dersler.Where(q => q.DersId == od.DersId).DefaultIfEmpty()
                                from ogr in gaziEntities.OgrenciDersler.Where(q => q.OgretmenDersId == s.OgretmenDersId).DefaultIfEmpty()
                                                                
                                select new {s.OgretmenDersId, ogr.OgrenciId, s.SinavId, s.EkleyenId, d.DersAdi, s.SinavAdi, s.SinavAciklama, s.BaslangicTarihi, s.BitisTarihi });


            if (txtDersAdi.Text != "")
                sinavListesi = sinavListesi.Where(q => q.DersAdi.StartsWith(txtDersAdi.Text));
            
            if (txtSinavAdi.Text != "")
                sinavListesi = sinavListesi.Where(q => q.SinavAdi.StartsWith(txtSinavAdi.Text));

           

            sinavListesi = sinavListesi.Where(q => q.OgretmenDersId == null || q.OgrenciId == kullaniciId);
            //sinavListesi = sinavListesi.

            //grdSinavlar.DataSource = sinavListesi.Take(200).OrderBy(q => q.DersAdi).ToList();
            var aaa = sinavListesi.Take(200).ToList();
            grdSinavlar.DataSource = sinavListesi.Take(200).ToList();
            grdSinavlar.DataBind();
        }

        protected void btnSinavaGir_Click(object sender, EventArgs e)
        {
            if (grdSinavlar.SelectedItems.Count > 0)
            {
                string sinavId = grdSinavlar.SelectedValues["SinavId"].ToString();
                Session.Add("SinavId", sinavId);
                Response.Redirect("~/Forms/OgrenciSinav.aspx");
            }
        }



    }
}