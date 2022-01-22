using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;

namespace GaziProje2014.Forms
{
    public partial class IcerikDisaYayin : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                GAZIDbContext gaziEntities = new GAZIDbContext();
                var duyurular = (from di in gaziEntities.DersIcerikler
                                 from od in gaziEntities.OgretmenDersler.Where(q => q.OgretmenDersId == di.OgretmenDersId).DefaultIfEmpty()
                                 from d in gaziEntities.Dersler.Where(q => q.DersId == od.DersId).DefaultIfEmpty()
                                 select new { di.IcerikId, di.IcerikAdi, d.DersAdi }).ToList();

                grdIcerikBasliklar.DataSource = duyurular;
                grdIcerikBasliklar.DataBind();
            }

        }


        protected void grdIcerikBasliklar_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (grdIcerikBasliklar.SelectedItems.Count > 0)
            {
                int icerikId = (int)grdIcerikBasliklar.SelectedValues["IcerikId"];
                GAZIDbContext gaziEntities = new GAZIDbContext();
                var dersicerik = gaziEntities.DersIcerikler.Where(q => q.IcerikId == icerikId).FirstOrDefault();
                
                hdnIcerikId.Value = dersicerik.IcerikId.ToString();
                hdnResimUrl.Value = dersicerik.ThumbnailPath;
                Imgthumbnail.ImageUrl = dersicerik.ThumbnailPath;

                chkPublic.Checked = dersicerik.GenelIcerik.Value;
                txtBaslik.Text = dersicerik.IcerikAdi;
                txtUrlName.Text = dersicerik.UrlName;
                txtIcerikUrl.Text = dersicerik.IcerikUrl;

                txtVideoSaniye.Text = dersicerik.VideoSaniye.ToString();
                txtUrlAciklama.Text = dersicerik.UrlAciklama;
                cbIcerikTipi.SelectedValue = dersicerik.IcerikTip.ToString();

            }
        }

        protected void btnYukle_Click(object sender, EventArgs e)
        {
            if (FileUpload1.HasFile) //Kullanıcı browse tuşuna basarak dosya seçtiyse aşağıdaki kodlar çalışacak.
            {
                string path = Server.MapPath("~") + "Genel/Thumbnails/" + FileUpload1.FileName;
                FileUpload1.SaveAs(path);
                Imgthumbnail.ImageUrl = "~/Genel/Thumbnails/" + FileUpload1.FileName;
                hdnResimUrl.Value = "~/Genel/Thumbnails/" + FileUpload1.FileName;
            }
            else
            {
                Response.Write("Dosya Yükleme Hatası");
            }
        }

        protected void btnKaydet_Click(object sender, EventArgs e)
        {
            int icerikId = Convert.ToInt32(hdnIcerikId.Value);
            GAZIDbContext gaziEntities = new GAZIDbContext();
            var dersicerik = gaziEntities.DersIcerikler.Where(q => q.IcerikId == icerikId).FirstOrDefault();

            dersicerik.GenelIcerik = chkPublic.Checked;
            dersicerik.ThumbnailPath = hdnResimUrl.Value;
            dersicerik.IcerikAdi = txtBaslik.Text;
            dersicerik.UrlName = txtUrlName.Text;

            if (txtVideoSaniye.Text != "")
                dersicerik.VideoSaniye = Convert.ToInt32(txtVideoSaniye.Text);

            dersicerik.UrlAciklama = txtUrlAciklama.Text;
            gaziEntities.SaveChanges();

        }

        protected void btnSiteMap_Click(object sender, EventArgs e)
        {
            string sitePath = "http://www.uegitim.com";
            string sitemap = "";

            sitemap = "<url>"
                     +"<loc>"+ sitePath +"/" + txtUrlName.Text + "</loc>"  
                     +"<video:video>"
                     +"<video:thumbnail_loc>"+sitePath + hdnResimUrl.Value + "</video:thumbnail_loc> "
                     +"<video:title>"+ txtBaslik.Text +"</video:title>"
                     +"<video:description>" + txtUrlAciklama.Text + "</video:description>"
                     +"<video:content_loc>" + sitePath + txtIcerikUrl.Text  + "</video:content_loc>"
                     +"<video:duration>" + txtVideoSaniye.Text + "</video:duration>"
                     +"</video:video>"
                     +"</url>";

           txtSiteMap.Text =sitemap;                       
       }


    }
}