using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using GaziProje2014.Data.Models;

namespace GaziProje2014
{
    public partial class Login : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void btnGiris_Click(object sender, EventArgs e)
        {

            if (txtKullaniciAdi.Value == "")
            {
                showMesaj("Kullanıcı Adı Boş Geçilemez");
                return;      
            }
            else if (txtKullaniciSifre.Value == "")
            {
                showMesaj("Kullanıcı Şifre Boş Geçilemez");
                return;     
            }
            else if (!Page.IsValid)
            {
                showMesaj("Güvenlik No Yanlış Girildi");
                return;
            }
            else
            {
                string KullaniciAdi = txtKullaniciAdi.Value;
                string KullaniciSifre = txtKullaniciSifre.Value;

                GAZIDbContext gaziEntities = new GAZIDbContext();
                Kullanicilar kullanici = gaziEntities.Kullanicilar.Where(q => q.KullaniciAdi == KullaniciAdi && q.KullaniciSifre == KullaniciSifre && q.Onay == true).FirstOrDefault();

                if (kullanici != null)
                {
                    Session.Remove("KullaniciAdi");
                    Session.Remove("KullaniciId");
                    Session.Remove("KullaniciTipiId");

                    Session.Add("KullaniciAdi", kullanici.KullaniciAdi);
                    Session.Add("KullaniciId", kullanici.KullaniciId);
                    Session.Add("KullaniciTipiId", kullanici.KullaniciTipi);
                    Response.Redirect("~/Forms/DefaultDuyuru.aspx");
                }              
            }
            


        }

        private void showMesaj(string Mesaj)
        {
            RadNotification1.Text = Mesaj;
            RadNotification1.Show();
        }

    }
}