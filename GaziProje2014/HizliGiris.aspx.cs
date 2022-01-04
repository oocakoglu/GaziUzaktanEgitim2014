using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;

namespace GaziProje2014
{
    public partial class HizliGiris : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void btnAdmin_Click(object sender, EventArgs e)
        {
            if (RadGrid1.SelectedItems.Count > 0)
            {
                int kullaniciId = Convert.ToInt32(RadGrid1.SelectedValues["KullaniciId"].ToString());

                GAZIEntities gaziEntities = new GAZIEntities();
                Kullanicilar kullanici = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == kullaniciId).FirstOrDefault();
                if (kullanici != null)
                {
                    Session.Remove("KullaniciAdi");
                    Session.Remove("KullaniciId");
                    Session.Remove("KullaniciTipiId");

                    Session.Add("KullaniciAdi", kullanici.KullaniciAdi);
                    Session.Add("KullaniciId", kullanici.KullaniciId);
                    Session.Add("KullaniciTipiId", kullanici.KullaniciTipi);


                    //** Skin
                    if ((kullanici.SkinName != "") && (kullanici.SkinName != null))
                        Session.Add("SkinName", kullanici.SkinName);
                    else
                        Session.Add("SkinName", "WebBlue");

                    //** BackGround
                    if ((kullanici.BackGround != "") && (kullanici.BackGround != null))
                        Session.Add("BackGround", kullanici.BackGround);
                    else
                        Session.Add("BackGround", "/Style/Background/Back03.jpg");

                    Response.Redirect("~/Forms/DefaultDuyuru.aspx");
                }
            }
        }


    }
}