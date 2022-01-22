using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using GaziProje2014.Data.Models;

namespace GaziProje2014.Forms
{
    public partial class DosyaYoneticisi : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

            if (!IsPostBack)
            {
                int KullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
                GAZIDbContext gaziEntities = new GAZIDbContext();
                string DokumanAdres = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == KullaniciId).Select(q => q.DokumanAdres).SingleOrDefault();

                if (DokumanAdres == null)
                {
                    Kullanicilar kullanicilar = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == KullaniciId).FirstOrDefault();
                    DokumanAdres = kullanicilar.Adi + kullanicilar.Soyadi;
                    DokumanAdres = "~/Dokumanlar/" + Common.SefURL(DokumanAdres);
                    kullanicilar.DokumanAdres = DokumanAdres;
                    gaziEntities.SaveChanges();
                    //Directory.CreateDirectory(DokumanAdres);

                    string sDirPath = Server.MapPath(DokumanAdres);
                    DirectoryInfo ObjSearchDir = new DirectoryInfo(sDirPath);
                    if (!ObjSearchDir.Exists)
                    {
                        ObjSearchDir.Create();
                    }

                }
                //FileExplorer1.Configuration.ViewPaths = new string[] { "~/Dokumanlar/TolgaKecik" };
                FileExplorer1.Configuration.ViewPaths = new string[] { DokumanAdres };
                FileExplorer1.Configuration.UploadPaths = new string[] { DokumanAdres };
                FileExplorer1.Configuration.DeletePaths = new string[] { DokumanAdres };
            }
            //ViewPaths="~/Dokumanlar" UploadPaths="~/Dokumanlar" DeletePaths="~/Dokumanlar"
        }
    }
}