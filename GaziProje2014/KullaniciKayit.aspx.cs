using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using Telerik.Web.UI;

namespace GaziProje2014.Pages
{
    public partial class KullaniciKayit : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                GAZIEntities gaziEntities = new GAZIEntities();

                //** Kullanıcı Tipi Id
                cbKullaniciTipleri.DataSource = gaziEntities.KullaniciTipleri.Where(q => q.KullaniciTipDurum == true).ToList();
                cbKullaniciTipleri.DataTextField = "KullaniciTipAdi";
                cbKullaniciTipleri.DataValueField = "KullaniciTipId";
                cbKullaniciTipleri.DataBind();

                //** Il Kodlari
                cbIlAdi.DataSource = gaziEntities.Il.ToList();
                cbIlAdi.DataTextField = "IlAdi";
                cbIlAdi.DataValueField = "IlKodu";
                cbIlAdi.DataBind();
            }
            else
            {
                txtSifre.Attributes["value"] = txtSifre.Text;
            }
        }

        protected void btnKaydet_Click(object sender, EventArgs e)
        {
            if (VeriKontrol())
            {
                GAZIEntities gaziEntities = new GAZIEntities();
                Kullanicilar Kullanici = new Kullanicilar();
                Kullanici.KullaniciTipi = Convert.ToInt32(cbKullaniciTipleri.SelectedValue);
                Kullanici.KullaniciAdi = txtKullaniciAdi.Text;
                Kullanici.KullaniciSifre = txtSifre.Text;
                Kullanici.Adi = txtAdi.Text;
                Kullanici.Soyadi = txtSoyadi.Text;
                Kullanici.Cinsiyet = Convert.ToInt32(cbCinsiyet.SelectedValue);
                Kullanici.DogumTarihi = dteDogumTarihi.SelectedDate;
                Kullanici.CepTel = txtCepTel.Text;
                Kullanici.EvTel = txtEvTel.Text;
                Kullanici.Email = txtemail.Text;
                Kullanici.Adres = txtAdres.Text;
                Kullanici.IlKodu = Convert.ToInt32(cbIlAdi.SelectedValue);
                Kullanici.IlceKodu = Convert.ToInt32(cbIlceAdi.SelectedValue);

                Kullanici.Onay = false;
                //if (Session["ResimUrl"] != null)
                //{
                //    Kullanici.Resim = Session["ResimUrl"].ToString();
                //}
                gaziEntities.Kullanicilar.Add(Kullanici);
                gaziEntities.SaveChanges();
                Temizle();
                ShowMesaj("Kullanıcı Kaydınız Başarıyla Yapılmıştır. Yöneticiden onay beklemektedir.");
            }
        }

        protected void btnAnaSayfa_Click(object sender, EventArgs e)
        {
            Response.Redirect("Default.aspx");
        }

        protected void btnVazgec_Click(object sender, EventArgs e)
        {
            Temizle();
        }
                
        protected void cbIlAdi_SelectedIndexChanged(object sender, RadComboBoxSelectedIndexChangedEventArgs e)
        {
            if (cbIlAdi.SelectedValue != null)
            {
                //** Il Kodlari
                cbIlceAdi.SelectedValue = null;
                int IlKodu = Convert.ToInt32(cbIlAdi.SelectedValue);

                GAZIEntities gaziEntities = new GAZIEntities();
                List<Ilce> ilce = gaziEntities.Ilce.Where(q => q.IlKodu == IlKodu).ToList();

                //** Il Kodlari
                cbIlceAdi.DataSource = ilce;
                cbIlceAdi.DataTextField = "IlceAdi";
                cbIlceAdi.DataValueField = "IlceKodu";
                cbIlceAdi.DataBind();
            }
        }

        private bool VeriKontrol()
        {

            if (cbKullaniciTipleri.SelectedValue == "")
            {
                ShowMesaj("Lütfen Kullanıcı Tipini Seçiniz");
                return false;
            }

            if (txtKullaniciAdi.Text == "")
            {
                ShowMesaj("Lütfen Kullanıcı Adını Yazınız");
                return false;
            }

            if (txtSifre.Text == "")
            {
                ShowMesaj("Lütfen Kullanıcı Şifresini Yazınız");
                return false;
            }

            if (txtAdi.Text == "")
            {
                ShowMesaj("Lütfen Adını Yazınız");
                return false;
            }

            if (txtSoyadi.Text == "")
            {
                ShowMesaj("Lütfen Soyadını Yazınız");
                return false;
            }

            if (cbCinsiyet.SelectedValue == "")
            {
                ShowMesaj("Lütfen  Cinsiyetini Seçiniz");
                return false;
            }

            if (dteDogumTarihi.SelectedDate.ToString() == "01.01.0001 00:00:00")
            {
                ShowMesaj("Lütfen  Doğum Tarihini Seçiniz");
                return false;
            }

            if (txtCepTel.Text == "")
            {
                ShowMesaj("Lütfen Cep Telefonunu Yazınız");
                return false;
            }

            if (cbIlAdi.SelectedValue == "")
            {
                ShowMesaj("Lütfen İli Seçiniz");
                return false;
            }

            if (cbIlceAdi.SelectedValue == "")
            {
                ShowMesaj("Lütfen İlçeyi Seçiniz");
                return false;
            }
            return true;
        }

        private void Temizle()
        {
            cbKullaniciTipleri.SelectedValue = null;
            txtKullaniciAdi.Text = "";
            txtSifre.Text = "";
            txtAdi.Text = "";
            txtSoyadi.Text = "";
            cbCinsiyet.SelectedValue = null;
            dteDogumTarihi.SelectedDate = null;

            txtCepTel.Text = "";
            txtEvTel.Text = "";
            txtemail.Text = "";
            txtAdres.Text = "";

            cbIlAdi.SelectedValue = null;
            cbIlceAdi.SelectedValue = null;
        }
        
        private void ShowMesaj(string Mesaj)
        {
            RadNotification1.Text = Mesaj;
            RadNotification1.Show();
        }


    }
}