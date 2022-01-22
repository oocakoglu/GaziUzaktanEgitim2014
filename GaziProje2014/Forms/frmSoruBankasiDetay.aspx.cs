using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using GaziProje2014.Data.Models;
using Telerik.Web.UI;

namespace GaziProje2014.Forms
{
    public partial class frmSoruBankasiDetay : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                rdDersler.DataSource = Common.GetDersler();
                rdDersler.DataTextField = "OgretmenDersAdi";
                rdDersler.DataValueField = "OgretmenDersId";
                rdDersler.DataBind();

                if (Session["OgretmenDersId"] != null)
                {
                    int ogretmenDersId = Convert.ToInt32(Session["OgretmenDersId"].ToString());
                    rdDersler.SelectedValue = ogretmenDersId.ToString();
                    rdDersler_SelectedIndexChanged(null, null);                   
                }                
            }
        }

        private void grdSorularBind()
        {
            GAZIDbContext gaziEntities = new GAZIDbContext();
            if (hdnOgretmenDersId.Value != "")
            {
                int dersId = Convert.ToInt32(hdnOgretmenDersId.Value);
                var sorular = (from s in gaziEntities.Sorular
                               where s.OgretmenDersId == dersId
                               select new { s.SoruId, s.SoruKonu, s.SoruIcerik }).ToList();

                grdSorular.DataSource = sorular;
                grdSorular.DataBind();
            }

        }

        protected void grdSorular_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (grdSorular.SelectedItems.Count > 0)
            {
                lblBilgi.Text = "";
                int soruId = (int)grdSorular.SelectedValues["SoruId"];
                GAZIDbContext gaziEntities = new GAZIDbContext();

                var sorular = gaziEntities.Sorular.Where(q => q.SoruId == soruId).FirstOrDefault();

                //** Goruntule Kısmı
                lblSoruIcerik.Text = sorular.SoruIcerik;
                imgSoruResim.ImageUrl = sorular.SoruResim;

                //rdCevaplar.
                rdCevaplar.Items.Clear();
                ListItem li1 = new ListItem(sorular.Cvp1, "1");
                rdCevaplar.Items.Add(li1);

                ListItem li2 = new ListItem(sorular.Cvp2, "2");
                rdCevaplar.Items.Add(li2);

                ListItem li3 = new ListItem(sorular.Cvp3, "3");
                rdCevaplar.Items.Add(li3);

                ListItem li4 = new ListItem(sorular.Cvp4, "4");
                rdCevaplar.Items.Add(li4);

                ListItem li5 = new ListItem(sorular.Cvp5, "5");
                rdCevaplar.Items.Add(li5);
                rdCevaplar.SelectedValue = sorular.DogruCvp.ToString();


                //** Duzenle Kısmı
                imgSoruResmiDuzenle.ImageUrl = sorular.SoruResim;
                txtSoruIcerik.Text = sorular.SoruIcerik;
                txtSoruKonu.Text = sorular.SoruKonu;
                hdnResimYol.Value = sorular.SoruResim;

                txtCvp1.Text = sorular.Cvp1;
                txtCvp2.Text = sorular.Cvp2;
                txtCvp3.Text = sorular.Cvp3;
                txtCvp4.Text = sorular.Cvp4;
                txtCvp5.Text = sorular.Cvp5;
                hdnSoruId.Value = sorular.SoruId.ToString();

                int dogruCvp = sorular.DogruCvp.Value;
                switch (dogruCvp)
                {
                    case 1: rdCvp1.Checked = true; break;
                    case 2: rdCvp2.Checked = true; break;
                    case 3: rdCvp3.Checked = true; break;
                    case 4: rdCvp4.Checked = true; break;
                    case 5: rdCvp5.Checked = true; break;
                }
            }
        }

        protected void rdDersler_SelectedIndexChanged(object sender, RadComboBoxSelectedIndexChangedEventArgs e)
        {
            string ogretmenDersIdStr = rdDersler.SelectedValue;
            if (ogretmenDersIdStr != "")
            {
                hdnOgretmenDersId.Value = ogretmenDersIdStr;
                grdSorularBind();
            }

        }

        protected void btnUpload_Click(object sender, EventArgs e)
        {
            if (fileUploadImage.HasFile)
            {
                String KayitYeri = "";
                KayitYeri = DateTime.Now.ToString();
                KayitYeri = KayitYeri.Replace(" ", "").Replace(":", "").Replace(".", "");
                string SaveLocation = Server.MapPath("Resim") + "\\" + "Soru" + KayitYeri + ".jpg";

                try
                {
                    fileUploadImage.PostedFile.SaveAs(SaveLocation);
                    //imgSoruResim.ImageUrl = "Resim\\Soru" + KayitYeri + ".jpg";
                    imgSoruResmiDuzenle.ImageUrl = "Resim\\Soru" + KayitYeri + ".jpg";
                    hdnResimYol.Value = "Resim\\Soru" + KayitYeri + ".jpg";
                }
                catch
                { }
            }

        }

        protected void btnResimSil_Click(object sender, System.EventArgs e)
        {
            if (hdnResimYol.Value != "")
            {
                string Dosya = MapPath(".") + "\\" + hdnResimYol.Value;

                FileInfo TheFile = new FileInfo(Dosya);
                if (TheFile.Exists)
                {
                    File.Delete(Dosya);
                }

                hdnResimYol.Value = "";
                imgSoruResmiDuzenle.ImageUrl = "";
            }

        }

        protected void btnGuncelle_Click(object sender, EventArgs e)
        {
            GAZIDbContext gaziEntities = new GAZIDbContext();
            Sorular sorular = null;
            if ((hdnSoruId.Value != "") && (hdnSoruId.Value != "0"))
            {
                int soruId = Convert.ToInt32(hdnSoruId.Value);
                sorular = gaziEntities.Sorular.Where(q => q.SoruId == soruId).FirstOrDefault();
            }
            else
            {
                sorular = new Sorular();
                gaziEntities.Sorular.Add(sorular);
            }

            sorular.SoruKonu = txtSoruKonu.Text;
            sorular.SoruIcerik = txtSoruIcerik.Text;
            sorular.Cvp1 = txtCvp1.Text;
            sorular.Cvp2 = txtCvp2.Text;
            sorular.Cvp3 = txtCvp3.Text;
            sorular.Cvp4 = txtCvp4.Text;
            sorular.Cvp5 = txtCvp5.Text;
            sorular.SoruResim = hdnResimYol.Value;
            sorular.OgretmenDersId = Convert.ToInt32(hdnOgretmenDersId.Value);
            sorular.EkleyenId = Convert.ToInt32(Session["KullaniciId"].ToString());
            sorular.KayitTrh = DateTime.Now;
            sorular.CvpSayisi = 5;

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
            else
            {
                lblBilgi.Text = "Lütfen Doğru Cevabı Seçiniz";
                return;
            }

            gaziEntities.SaveChanges();
            grdSorularBind();
            rtbstMain.SelectedIndex = 0;
            soruMultiPage.SelectedIndex = 0;
        }

        protected void btnYeniSoru_Click(object sender, EventArgs e)
        {
            formTemizle();
            rtbstMain.SelectedIndex = 1;
            soruMultiPage.SelectedIndex = 1;

        }

        protected void btnSoruSil_Click(object sender, EventArgs e)
        {
            if (grdSorular.SelectedItems.Count > 0)
            {
                int soruId = (int)grdSorular.SelectedValues["SoruId"];
                GAZIDbContext gaziEntities = new GAZIDbContext();
                Sorular sorular = gaziEntities.Sorular.Where(x => x.SoruId == soruId).FirstOrDefault();
                gaziEntities.Sorular.Remove(sorular);
                gaziEntities.SaveChanges();
                grdSorularBind();
                formTemizle();
            }
        }

        private void formTemizle()
        {
            grdSorular.SelectedIndexes.Clear();
            lblSoruIcerik.Text = "";
            imgSoruResim.ImageUrl = "";
            rdCevaplar.Items.Clear();

            imgSoruResmiDuzenle.ImageUrl = "";
            txtSoruIcerik.Text = "";
            txtSoruKonu.Text = "";
            hdnResimYol.Value = "";

            txtCvp1.Text = "";
            txtCvp2.Text = "";
            txtCvp3.Text = "";
            txtCvp4.Text = "";
            txtCvp5.Text = "";
            hdnSoruId.Value = "";
        }
    }
}