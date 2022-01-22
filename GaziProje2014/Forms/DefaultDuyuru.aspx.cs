using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using GaziProje2014.Data;

namespace GaziProje2014.Forms
{
    public partial class DefaultDuyuru : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            int KullaniciTipiId = Convert.ToInt32(Session["KullaniciTipiId"].ToString());

            GAZIDbContext gaziEntities = new GAZIDbContext();
            var duyurular = (from d in gaziEntities.Duyurular                           
                             join k in gaziEntities.DuyuruKullanicilar on d.DuyuruId equals k.DuyuruId
                             where k.KullaniciTipiId == KullaniciTipiId
                             select d).OrderByDescending(q => q.DuyuruTarihi).Take(15).ToList();

           
            string ContentHtml = "";
            foreach (var item in duyurular)
            {                             
                ContentHtml += "<p class=\"MsoNormal\">";
                ContentHtml += "<b><span style=\"color:maroon\">" + item.DuyuruAdi + " (" + item.DuyuruTarihi.Value.ToShortDateString()+ ") </span></b><span style=\"color: black\"><br />";
                ContentHtml += "</p>";

                ContentHtml += "<p class=\"MsoNormal\">" + item.DuyuruIcerik + "</p>";
                ContentHtml += "<hr width=\"100%\" />";
            }
            var h4 = new HtmlGenericControl();
            h4.InnerHtml = ContentHtml;
            DefaultDuyuruContent.Controls.Add(h4);

        }
    }
}