using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Xml;
using System.Xml.Linq;
using GaziProje2014.Data;


namespace GaziProje2014.Forms
{
    public partial class DigerAyarlar : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void btnKaydet_Click(object sender, EventArgs e)
        {
            try
            {
                string xml = btnTxtSiteMap.Text;

                string path = Server.MapPath("~") + "Sitemap.xml";
                File.WriteAllText(path, xml);
                //File.WriteAllText(path, xml, Encoding.ASCII);
            }
            catch
            {

            }
        }

        protected void btnSeo_Click(object sender, EventArgs e)
        {
           // string sitePath = "http://www.uegitim.com";
           // string sitemap = "";

           // sitemap = "<url>"
           //          +"<loc>"+ sitePath +"/" + txtUrlName.Text + "</loc>"  
           //          +"<video:video>"
           //          +"<video:thumbnail_loc>"+sitePath + hdnResimUrl.Value + "</video:thumbnail_loc> "
           //          +"<video:title>"+ txtBaslik.Text +"</video:title>"
           //          +"<video:description>" + txtUrlAciklama.Text + "</video:description>"
           //          +"<video:content_loc>" + sitePath + txtIcerikUrl.Text  + "</video:content_loc>"
           //          +"<video:duration>" + txtVideoSaniye.Text + "</video:duration>"
           //          +"</video:video>"
           //          +"</url>";

           //txtSiteMap.Text =sitemap; 

            string sitePath = "http://www.uegitim.com";
            string sitemap = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                            +"<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\" "
                            +"        xmlns:image=\"http://www.google.com/schemas/sitemap-image/1.1\" " 
                            +"        xmlns:video=\"http://www.google.com/schemas/sitemap-video/1.1\">";

            string sitemapUrl = "<url>"
                               + "<loc>http://uegitim.com/</loc>"
                               + "<changefreq>never</changefreq>"
                               + "</url>"
                               + "<url>"
                               + "<loc>http://uegitim.com/KullaniciKayit.aspx</loc>"
                               + "<changefreq>never</changefreq>"
                               + "</url>";

            GAZIDbContext gaziEntities = new GAZIDbContext();
            var dersicerikler = gaziEntities.DersIcerikler.Where(q => q.GenelIcerik == true).ToList();           
            foreach (var item in dersicerikler)
	        {
		        sitemapUrl = sitemapUrl 
                + "<url>"
                + "<loc>" + sitePath +"/Genel/"+ item.UrlName + "</loc>"
                + "<changefreq>weekly</changefreq>";

                if ((item.IcerikTip == 2) && ((item.IcerikUrl.ToString().IndexOf(".mp4") != -1)))
                {
                    sitemapUrl = sitemapUrl
                    + "<video:video>"
                    + "<video:thumbnail_loc>" + sitePath + item.ThumbnailPath.Replace("~", "") + "</video:thumbnail_loc>"
                    + "<video:title>" + item.IcerikAdi + "</video:title>"
                    + "<video:description>" + item.UrlAciklama + "</video:description>"
                    + "<video:content_loc>" + sitePath + item.IcerikUrl + "</video:content_loc>";
                    if (item.VideoSaniye != null)
                        sitemapUrl = sitemapUrl + "<video:duration>" + item.VideoSaniye.ToString() + "</video:duration>";
                    sitemapUrl = sitemapUrl + "</video:video>";
                }
                sitemapUrl = sitemapUrl + "</url>";
	        }

            btnTxtSiteMap.Text  = sitemap + sitemapUrl + "</urlset>";

        }





        //<?xml version="1.0" encoding="UTF-8"?>
        //<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" 
        //  xmlns:image="http://www.google.com/schemas/sitemap-image/1.1" 
        // xmlns:video="http://www.google.com/schemas/sitemap-video/1.1">
        // <url> 
        //   <loc>http://www.example.com/foo.html</loc> 
        //    <image:image>
        //       <image:loc>http://example.com/image.jpg</image:loc> 
        //    </image:image>
        //    <video:video>     
        //      <video:content_loc>
        //        http://www.example.com/video123.flv
        //      </video:content_loc>
        //      <video:player_loc allow_embed="yes" autoplay="ap=1">
        //        http://www.example.com/videoplayer.swf?video=123
        //      </video:player_loc>
        //      <video:thumbnail_loc>
        //        http://www.example.com/thumbs/123.jpg
        //      </video:thumbnail_loc>
        //      <video:title>Grilling steaks for summer</video:title>  
        //      <video:description>
        //        Get perfectly done steaks every time
        //      </video:description>
        //    </video:video>
        //  </url>
        //</urlset>


    }
}