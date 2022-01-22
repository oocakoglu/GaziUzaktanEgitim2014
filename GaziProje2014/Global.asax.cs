using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.SessionState;
using GaziProje2014.Data;

namespace GaziProje2014
{
    public class Global : System.Web.HttpApplication
    {
        protected void Application_Start(object sender, EventArgs e)
        {
        }

        protected void Application_BeginRequest(object sender, EventArgs e)
        {



            string DosyaYolu = Request.RawUrl;
            if (DosyaYolu.IndexOf(".") == -1)
            {
                if (DosyaYolu.IndexOf("/Genel/") != -1)
                {
                    string[] path = DosyaYolu.Split('/');
                    string urlName = path[2];

                    GAZIDbContext gaziEntities = new GAZIDbContext();
                    var ders = (from d in gaziEntities.DersIcerikler
                                where d.GenelIcerik == true && d.UrlName == urlName
                                select new {d.IcerikId, d.IcerikTip}).FirstOrDefault();

                    if (ders != null)
                    {
                        if (ders.IcerikTip == 1)
                           Context.RewritePath("~/Genel/TextIcerik.aspx", "", "id=" + ders.IcerikId, true);
                        else if (ders.IcerikTip == 2)
                           Context.RewritePath("~/Genel/VideoIcerik.aspx", "", "id=" + ders.IcerikId, true);

                    }
                }
            }


        }

    }
}