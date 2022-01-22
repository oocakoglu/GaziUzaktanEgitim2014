using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace GaziProje2014.Data
{
    public static class Common
    {
        public static string SefURL(object Kelime)
        {
            string Degisecek = Kelime.ToString();
            //Degisecek = Degisecek.Trim('-');
            Degisecek = Degisecek.Trim(' ');
            //Degisecek = Degisecek.ToLower();//stringi küçük harfli hale getiriyoruz.
            Degisecek = Degisecek.Replace("ü", "u");
            Degisecek = Degisecek.Replace("ğ", "g");
            Degisecek = Degisecek.Replace("ö", "o");
            Degisecek = Degisecek.Replace("ş", "s");
            Degisecek = Degisecek.Replace("ç", "c");
            Degisecek = Degisecek.Replace("ı", "i");

            Degisecek = Degisecek.Replace("Ü", "U");
            Degisecek = Degisecek.Replace("Ğ", "G");
            Degisecek = Degisecek.Replace("Ö", "O");
            Degisecek = Degisecek.Replace("Ş", "S");
            Degisecek = Degisecek.Replace("Ç", "c");

            Degisecek = Degisecek.Replace("!", "");
            Degisecek = Degisecek.Replace("?", "");
            Degisecek = Degisecek.Replace(".", "");
            Degisecek = Degisecek.Replace("!", "");
            Degisecek = Degisecek.Replace("'", "-");
            Degisecek = Degisecek.Replace("#", "sharp");
            Degisecek = Degisecek.Replace(";", "");
            Degisecek = Degisecek.Replace(")", "");
            Degisecek = Degisecek.Replace("[", "");
            Degisecek = Degisecek.Replace("]", "");
            Degisecek = Degisecek.Replace("(", "");
            Degisecek = Degisecek.Replace(" ", "");
            Degisecek = Degisecek.Replace("-", "");
            //Degisecek = Degisecek.Replace("---", "");
            //Degisecek = Degisecek.Replace("----", "");
            return Degisecek;
        }

        public static List<DersList> GetDersler()
        {
            var currentSession = HttpContext.Current.Session;
            int kullaniciTipiId = (int)currentSession["KullaniciTipiId"];
            int kullaniciId = (int)currentSession["KullaniciId"];
            GAZIDbContext gaziEntities = new GAZIDbContext();
            List<DersList> result;

            if (kullaniciTipiId == 1)
            {
                result = (from od in gaziEntities.OgretmenDersler
                          join d in gaziEntities.Dersler on od.DersId equals d.DersId
                          join k in gaziEntities.Kullanicilar on od.OgretmenId equals k.KullaniciId
                          where od.UstOnay == true
                          select new DersList { OgretmenDersId = od.OgretmenDersId,
                                                OgretmenDersAdi = d.DersAdi + " (" + k.Adi + " " + k.Soyadi + ")"
                          }).ToList();

            }
            else
            {
                result = (from od in gaziEntities.OgretmenDersler
                          join d in gaziEntities.Dersler on od.DersId equals d.DersId
                          join k in gaziEntities.Kullanicilar on od.OgretmenId equals k.KullaniciId
                          where od.UstOnay == true && od.OgretmenId == kullaniciId
                          select new DersList
                          {
                              OgretmenDersId = od.OgretmenDersId,
                              OgretmenDersAdi = d.DersAdi + " (" + k.Adi + " " + k.Soyadi + ")"
                          }).ToList();
            }
            return result;
        }

        public class DersList
        {
            public int OgretmenDersId { get; set; }

            public string OgretmenDersAdi { get; set; }
        }

        //private class AcilanDers
        //{
        //    public int OgretmenDersId { get; set; }
        //    public int? OgretmenId { get; set; }
        //    public int? DersId { get; set; }
        //    public string DersiVeren { get; set; }
        //    public string DersAdi { get; set; }
        //    public string DersAciklama { get; set; }
        //    public int? DersAlanOgrenci { get; set; }
        //}  
    }
}