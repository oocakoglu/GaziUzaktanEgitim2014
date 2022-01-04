using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using Telerik.Web.UI;

namespace GaziProje2014.Forms
{
    public partial class KullaniciBilgisi : System.Web.UI.Page
    {
        

        protected void Page_Load(object sender, EventArgs e)
        {
            int KullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            if (!IsPostBack)
            {
                FillForm(KullaniciId);
            }
        }

        private void FillForm(int kullaniciId)
        {
            GAZIEntities gaziEntities = new GAZIEntities();

            Kullanicilar kullanicilar = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == kullaniciId).FirstOrDefault();
            if (kullanicilar != null)
            {
                txtKullaniciAdi.Text = kullanicilar.KullaniciAdi;
                txtSifre.Text = kullanicilar.KullaniciSifre;
                txtAdi.Text = kullanicilar.Adi;
                txtSoyadi.Text = kullanicilar.Soyadi;
                cbKullaniciTipleri.SelectedValue = kullanicilar.KullaniciTipi.ToString();
                cbCinsiyet.SelectedValue = kullanicilar.Cinsiyet.ToString();

                if (kullanicilar.DogumTarihi != null)
                    dteDogumTarihi.SelectedDate = kullanicilar.DogumTarihi;

                txtCepTel.Text = kullanicilar.CepTel;
                txtEvTel.Text = kullanicilar.EvTel;
                txtemail.Text = kullanicilar.Email;
                txtAdres.Text = kullanicilar.Adres;
                if (kullanicilar.Resim != "")
                { 
                  hdnResimUrl.Value = kullanicilar.Resim;
                  ImgProfilResim.ImageUrl = kullanicilar.Resim;
                }

                //** Kullanici Tipleri
                var kullaniciTipleri = gaziEntities.KullaniciTipleri.Where(q => q.KullaniciTipId == kullanicilar.KullaniciTipi).ToList();
                cbKullaniciTipleri.DataSource = kullaniciTipleri;
                cbKullaniciTipleri.DataValueField = "KullaniciTipId";
                cbKullaniciTipleri.DataTextField = "KullaniciTipAdi";
                cbKullaniciTipleri.DataBind();

                //** Il 
                var il = gaziEntities.Il.OrderBy(q => q.IlKodu).ToList();
                cbIlAdi.DataSource = il;
                cbIlAdi.DataValueField = "IlKodu";
                cbIlAdi.DataTextField = "IlAdi";
                cbIlAdi.DataBind();

                //**Ilce
                if (kullanicilar.IlKodu != null)
                {
                    cbIlAdi.SelectedValue = kullanicilar.IlKodu.ToString();
                    var ilce = gaziEntities.Ilce.Where(q => q.IlKodu == kullanicilar.IlKodu).ToList();
                    cbIlceAdi.DataSource = ilce;
                    cbIlceAdi.DataValueField = "IlceKodu";
                    cbIlceAdi.DataTextField = "IlceAdi";
                    cbIlceAdi.DataBind();
                    if (kullanicilar.IlceKodu != null)
                        cbIlceAdi.SelectedValue = kullanicilar.IlceKodu.ToString();
                }
            }

        }

        protected void cbIlAdi_SelectedIndexChanged(object sender, RadComboBoxSelectedIndexChangedEventArgs e)
        {
            if (cbIlAdi.SelectedValue != null)
            {
                GAZIEntities gaziEntities = new GAZIEntities();
                cbIlceAdi.SelectedValue = null;
                int IlKodu = Convert.ToInt32(cbIlAdi.SelectedValue);
                var ilce = gaziEntities.Ilce.Where(q => q.IlKodu == IlKodu).ToList();
                cbIlceAdi.DataSource = ilce;
                cbIlceAdi.DataValueField = "IlceKodu";
                cbIlceAdi.DataTextField = "IlceAdi";
                cbIlceAdi.DataBind();
            }
        }

        protected void btnYukle_Click(object sender, EventArgs e)
        {

            if (flupldResim.HasFile)
            {
                String KayitYeri = "";
                KayitYeri = DateTime.Now.ToString();
                KayitYeri = KayitYeri.Replace(" ", "").Replace(":", "").Replace(".", "");
                string SaveLocation = Server.MapPath("Resim") + "\\" + "Foto" + KayitYeri + ".jpg";

                try
                {
                    flupldResim.PostedFile.SaveAs(SaveLocation);    
                    ImgProfilResim.ImageUrl = "Resim\\Foto" + KayitYeri + ".jpg";
                    hdnResimUrl.Value = "Resim\\Foto" + KayitYeri + ".jpg";
                }
                catch
                { }                
            }
            else
            {
                Response.Write("Dosya Yükleme Hatası");
            }
        }
        
        protected void btnKaydet_Click(object sender, EventArgs e)
        {
            int KullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            using (GAZIEntities gaziEntities = new GAZIEntities())
            {
                Kullanicilar Kullanici = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == KullaniciId).FirstOrDefault();
                Kullanici.KullaniciTipi = Convert.ToInt32(cbKullaniciTipleri.SelectedValue);
                Kullanici.KullaniciAdi = txtKullaniciAdi.Text;
                Kullanici.KullaniciSifre = txtSifre.Text;
                Kullanici.Adi = txtAdi.Text;
                Kullanici.Soyadi = txtSoyadi.Text;
                Kullanici.Cinsiyet = Convert.ToInt32(cbCinsiyet.SelectedValue);
                if (dteDogumTarihi.SelectedDate != null)
                  Kullanici.DogumTarihi = dteDogumTarihi.SelectedDate;
                Kullanici.CepTel = txtCepTel.Text;
                Kullanici.EvTel = txtEvTel.Text;
                Kullanici.Email = txtemail.Text;
                Kullanici.Adres = txtAdres.Text;
                if (cbIlAdi.SelectedValue != null)
                  Kullanici.IlKodu = Convert.ToInt32(cbIlAdi.SelectedValue);
                if (cbIlceAdi.SelectedValue != null)
                  Kullanici.IlceKodu = Convert.ToInt32(cbIlceAdi.SelectedValue);
                if (hdnResimUrl.Value != null)
                   Kullanici.Resim = hdnResimUrl.Value;                      
                gaziEntities.SaveChanges();
                ShowMesaj("Bilgileriniz Başarıyla Güncellenmiştir.");
            }
        }

        private void ShowMesaj(string Mesaj)
        {
            RadNotification1.Text = Mesaj;
            RadNotification1.Show();
        }

    }
}