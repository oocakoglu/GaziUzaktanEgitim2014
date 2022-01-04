using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using Telerik.Web.UI;

namespace GaziProje2014.Forms
{
    public partial class SoruDetay : System.Web.UI.Page
    {
        private void FillForm(int SoruId)
        {
            GAZIEntities gaziEntities = new GAZIEntities();

            //** Ana Bilgi
            var soru = gaziEntities.Sorular.Where(q => q.SoruId == SoruId).FirstOrDefault();
            rdDersler.SelectedValue = soru.OgretmenDersId.ToString();
            txtDersKonu.Text = soru.SoruKonu;
            txtSoruIcerik.Text = soru.SoruIcerik;
            imgSoruResim.ImageUrl = soru.SoruResim;
            txtResimYol.Text = soru.SoruResim; ;

            txtCvp1.Text = soru.Cvp1;
            txtCvp2.Text = soru.Cvp2;
            txtCvp3.Text = soru.Cvp3;
            txtCvp4.Text = soru.Cvp4;
            txtCvp5.Text = soru.Cvp5;


            int dogruCvp = soru.DogruCvp.Value;
            switch (dogruCvp)
            {
                case 1: rdCvp1.Checked = true; break;
                case 2: rdCvp2.Checked = true; break;
                case 3: rdCvp3.Checked = true; break;
                case 4: rdCvp4.Checked = true; break;
                case 5: rdCvp5.Checked = true; break;
            }

            //** Eğer soru bir sınavda kullanılmıssa
            int soruSinav = gaziEntities.SinavDetay.Where(q => q.SoruId == SoruId).Count();
            if (soruSinav > 0)
            {
                rdDersler.Enabled = false;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {

            if (!IsPostBack)
            {
                rdDersler.DataSource = Common.GetDersler();
                rdDersler.DataTextField = "OgretmenDersAdi";
                rdDersler.DataValueField = "OgretmenDersId";
                rdDersler.DataBind();

                //** Soru Dersi Sabit Olsun
                if (Session["soruOgretmenDersId"] != null)
                {
                    string soruOgretmenDersId = Session["soruOgretmenDersId"].ToString();
                    rdDersler.SelectedValue = soruOgretmenDersId;
                    rdDersler.Enabled = false;
                }

                //** Soru Duzenleme
                if (Session["SoruId"] != null)
                {
                    int soruId = Convert.ToInt32(Session["SoruId"].ToString());
                    FillForm(soruId);
                }
                else
                {
                    if (Session["SoruSinavId"] != null)
                    {
                        GAZIEntities gaziEntities = new GAZIEntities();
                        int sinavId = Convert.ToInt32(Session["SoruSinavId"].ToString());
                        string dersId = gaziEntities.Sinav.Where(q => q.SinavId == sinavId).Select(q => q.OgretmenDersId).SingleOrDefault().ToString();
                        rdDersler.SelectedValue = dersId;
                        rdDersler.Enabled = false;
                    }
                }


                //SoruOgretmenDersId
            }

        }

        protected void btnResimYukle_Click(object sender, System.EventArgs e)
        {
            if (flupldResim.HasFile)
            {
                String KayitYeri = "";
                KayitYeri = DateTime.Now.ToString();
                KayitYeri = KayitYeri.Replace(" ", "").Replace(":", "").Replace(".", "");
                string SaveLocation = Server.MapPath("Resim") + "\\" + "Soru" + KayitYeri + ".jpg";

                try
                {
                    flupldResim.PostedFile.SaveAs(SaveLocation);
                    imgSoruResim.ImageUrl = "Resim\\Soru" + KayitYeri + ".jpg";
                    txtResimYol.Text = "Resim\\Soru" + KayitYeri + ".jpg";
                    //ImgProfilResim.ImageUrl = "Resim\\Foto" + KayitYeri + ".jpg";
                    //hdnResimUrl.Value = "Resim\\Foto" + KayitYeri + ".jpg";
                }
                catch
                { }
            }
        }

        protected void btnResimSil_Click(object sender, System.EventArgs e)
        {
            string Dosya = MapPath(".") + "\\" + txtResimYol.Text;

            FileInfo TheFile = new FileInfo(Dosya);
            if (TheFile.Exists)
            {
                File.Delete(Dosya);
            }

            imgSoruResim.ImageUrl = "";
            txtResimYol.Text = "";
        }

        protected void btnGuncelle_Click(object sender, EventArgs e)
        {
            if (VeriKontrol())
            {
                GAZIEntities gaziEntities = new GAZIEntities();
                Sorular sorular;

                if (Session["SoruId"] != null)
                {
                    int soruId = Convert.ToInt32(Session["SoruId"].ToString());
                    sorular = gaziEntities.Sorular.Where(q => q.SoruId == soruId).FirstOrDefault();
                    Session.Remove("SoruId");
                }
                else
                {
                    sorular = new Sorular();
                    gaziEntities.Sorular.Add(sorular);
                }

                sorular.OgretmenDersId = Convert.ToInt32(rdDersler.SelectedValue);
                sorular.SoruIcerik = txtSoruIcerik.Text;
                sorular.SoruKonu = txtDersKonu.Text;
                sorular.SoruResim = txtResimYol.Text;
                sorular.CvpSayisi = 5;
                sorular.Cvp1 = txtCvp1.Text;
                sorular.Cvp2 = txtCvp2.Text;
                sorular.Cvp3 = txtCvp3.Text;
                sorular.Cvp4 = txtCvp4.Text;
                sorular.Cvp5 = txtCvp5.Text;

                if (rdCvp1.Checked)
                    sorular.DogruCvp = 1;
                else if (rdCvp2.Checked)
                    sorular.DogruCvp = 2;
                else if (rdCvp3.Checked)
                    sorular.DogruCvp = 3;
                else if (rdCvp4.Checked)
                    sorular.DogruCvp = 4;
                else if (rdCvp5.Checked)
                    sorular.DogruCvp = 5;

                sorular.EkleyenId = 1;
                sorular.KayitTrh = DateTime.Now;
                gaziEntities.SaveChanges();


                if (Session["SoruSinavId"] != null)
                {
                    int sinavId = Convert.ToInt32(Session["SoruSinavId"].ToString());
                    int soruId = sorular.SoruId;
                    Data.SinavDetay sinavDetay;
                    sinavDetay = gaziEntities.SinavDetay.Where(q => q.SinavId == sinavId && q.SoruId == soruId).FirstOrDefault();
                    if (sinavDetay == null)
                    {
                        sinavDetay = new Data.SinavDetay();
                        sinavDetay.SoruId = soruId;
                        sinavDetay.SinavId = sinavId;
                        gaziEntities.SinavDetay.Add(sinavDetay);
                        gaziEntities.SaveChanges();
                    }
                    Session.Add("AktifTab", 1);
                    Response.Redirect("~/Forms/SinavDetay.aspx");
                }
                else if (Session["soruOgretmenDersId"] != null)
                {
                    Response.Redirect("~/Forms/SoruBankasiDetay.aspx");
                }

                if (Session["BackPage"] != null)
                    Response.Redirect(Session["BackPage"].ToString());
            }

        }

        private bool VeriKontrol()
        {
            if (txtSoruIcerik.Text == "")
            {
                ShowMesaj("Soru Alanını Boş Geçemezsiniz");
                return false;
            }
            else if (txtCvp1.Text == "" || txtCvp2.Text == "")
            {
                ShowMesaj("En az iki cevap girmeniz gerekmektedir");
                return false;
            }
            else if (!(rdCvp1.Checked || rdCvp2.Checked || rdCvp3.Checked || rdCvp4.Checked || rdCvp5.Checked))
            {
                ShowMesaj("Lütfen Doğru cevabı Seçiniz");
                return false;
            }
            

            return true;
        }

        private void ShowMesaj(string Mesaj)
        {
            RadNotification1.Text = Mesaj;
            RadNotification1.Show();
        }

    }
}