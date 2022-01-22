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
    public partial class SinavDetay : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                rdcmbOgretmenOnayliDersler.DataSource = Common.GetDersler();
                rdcmbOgretmenOnayliDersler.DataTextField = "OgretmenDersAdi";
                rdcmbOgretmenOnayliDersler.DataValueField = "OgretmenDersId";
                rdcmbOgretmenOnayliDersler.DataBind();


                if (Session["SinavId"] != null)
                {
                    int sinavId = Convert.ToInt32(Session["SinavId"].ToString());                    
                    FillForm(sinavId);

                    //if (Session["AktifTab"] != null)
                    //{
                    //    int aktifTab = Convert.ToInt32(Session["AktifTab"].ToString());
                    //    rtbstMain.SelectedIndex = aktifTab;
                    //    RadMultiPage1.SelectedIndex = aktifTab;
                    //    Session.Remove("AktifTab");
                    //}
                }
                else
                {
                    hdnSinavId.Value = "0";
                }
            }
        }

        private void FillForm(int SinavId)
        {
            GAZIDbContext gaziEntities = new GAZIDbContext();

            //** Ana Bilgi
            var sinav = gaziEntities.Sinav.Where(q => q.SinavId == SinavId).FirstOrDefault();
            rdcmbOgretmenOnayliDersler.SelectedValue = sinav.OgretmenDersId.ToString();
            txtSinavAdi.Text = sinav.SinavAdi;
            //txtSinavSure.Text = sinavlar.Sure.ToString();
            txtSinavAciklama.Text = sinav.SinavAciklama;
            dteBaslangicTarihi.SelectedDate = sinav.BaslangicTarihi;
            dteBitisTarihi.SelectedDate = sinav.BitisTarihi;
            hdnSinavId.Value = SinavId.ToString();


            //** Detay Bilgisi
            var sinavDetay = (from sd in gaziEntities.SinavDetay
                              where sd.SinavId == SinavId
                              join so in gaziEntities.Sorular on sd.SoruId equals so.SoruId
                              select new
                              {
                                  sd.SinavDetayId,
                                  so.SoruId,
                                  so.OgretmenDersId,
                                  so.SoruIcerik,
                                  so.SoruKonu,
                                  so.SoruResim,
                                  so.CvpSayisi,
                                  so.DogruCvp,
                                  so.Cvp1,
                                  so.Cvp2,
                                  so.Cvp3,
                                  so.Cvp4,
                                  so.Cvp5
                              }).ToList();

            RadListView1.DataSource = sinavDetay;
            RadListView1.DataBind();
        }

        protected void RadListView1_ItemDataBound(object sender, Telerik.Web.UI.RadListViewItemEventArgs e)
        {
            RadWindowManager1.Windows.Clear();
            Control cntrol = ((Label)e.Item.FindControl("lblSoruIcerik"));
            if (cntrol != null)
            {
                int CvpSayi = Convert.ToInt32(((Label)e.Item.FindControl("lblCvpSayisi")).Text);
                int dogruCvp = Convert.ToInt32(((Label)e.Item.FindControl("lblDogruCvp")).Text);

                //((Label)e.Item.FindControl("CvpSayisiLabel")).Visible = false;
                for (int i = 1; i <= CvpSayi; i++)
                {
                    ListItem li = new ListItem(((Label)e.Item.FindControl("Cvp" + i.ToString() + "Label")).Text, "Cvp" + i.ToString());
                    li.Enabled = false;
                    if (i == dogruCvp)
                        li.Selected = true;

                    ((RadioButtonList)e.Item.FindControl("rblCvp")).Items.Add(li);
                    ((Label)e.Item.FindControl("Cvp" + i.ToString() + "Label")).Visible = false;
                }
            }
        }

        //protected void btnSoruDuzenle_Click(object sender, System.EventArgs e)
        //{
        //    RadButton button = sender as RadButton;
        //    RadListViewDataItem Item = button.Parent as RadListViewDataItem;
        //    Label lblSoruId = ((Label)Item.FindControl("lblSoruId"));
        //    int soruId = Convert.ToInt32(lblSoruId.Text);
        //    int sinavId = Convert.ToInt32(hdnSinavId.Value);

        //    Session.Add("SoruId", soruId);
        //    Session.Add("SoruSinavId", sinavId);
        //    Response.Redirect("~/Forms/SoruDetay.aspx");
        //}



        //protected void btnSoruEkle_Click(object sender, System.EventArgs e)
        //{
        //    int sinavId = Convert.ToInt32(hdnSinavId.Value);

        //    if (sinavId > 0)
        //    {
        //        Session.Add("SoruSinavId", sinavId);                
        //        Response.Redirect("~/Forms/SoruDetay.aspx");
        //    }
        //}

        protected void btnSoruCikar_Click(object sender, System.EventArgs e)
        {
            RadWindowManager1.Windows.Clear();
            if ((hdnSinavId.Value != "") && (hdnSinavId.Value != "0"))
            {
                int sinavId = Convert.ToInt32(hdnSinavId.Value);
                RadButton button = sender as RadButton;
                RadListViewDataItem Item = button.Parent as RadListViewDataItem;
                Label lblSinavDetayId = ((Label)Item.FindControl("lblSinavDetayId"));
                int sinavDetayId = Convert.ToInt32(lblSinavDetayId.Text);

                GAZIDbContext gaziEntities = new GAZIDbContext();
                Data.Models.SinavDetay sinavDetay = gaziEntities.SinavDetay.Where(q => q.SinavDetayId == sinavDetayId).FirstOrDefault();
                gaziEntities.SinavDetay.Remove(sinavDetay);
                gaziEntities.SaveChanges();
                FillForm(sinavId);
            }
        }

        protected void btnKaydet_Click(object sender, EventArgs e)
        {
            RadWindowManager1.Windows.Clear();
         
            if (CheckValues())
            {
                GAZIDbContext gaziEntities = new GAZIDbContext();
                Data.Models.Sinav sinav = null;
                if ((hdnSinavId.Value != "") && (hdnSinavId.Value != "0"))
                {
                    int sinavId = Convert.ToInt32(hdnSinavId.Value);
                    sinav = gaziEntities.Sinav.Where(q => q.SinavId == sinavId).FirstOrDefault();
                }
                else
                {
                    sinav = new Data.Models.Sinav();
                    gaziEntities.Sinav.Add(sinav);

                    sinav.KayitTrh = DateTime.Now;
                    sinav.EkleyenId = Convert.ToInt32(Session["KullaniciId"].ToString());
                }

                sinav.SinavAdi = txtSinavAdi.Text;
                sinav.SinavAciklama = txtSinavAciklama.Text;
                sinav.BaslangicTarihi = dteBaslangicTarihi.SelectedDate;
                sinav.BitisTarihi = dteBitisTarihi.SelectedDate;
                sinav.Sure = Convert.ToInt32(txtSinavSure.Text);

                if (chkGenelSinav.Checked)
                    sinav.OgretmenDersId = null;
                else
                    sinav.OgretmenDersId = Convert.ToInt32(rdcmbOgretmenOnayliDersler.SelectedValue);

                gaziEntities.SaveChanges();
                hdnSinavId.Value = sinav.SinavId.ToString();
            }
        }

        protected void btnSoruEkle_Click(object sender, EventArgs e)
        {
            if ((hdnSinavId.Value != "") && (hdnSinavId.Value != "0"))
            {
                RadWindow window2 = new RadWindow();

                window2.ID = "RadWindow2";
                window2.NavigateUrl = "SinavSoruSecim.aspx?SinavId=" + hdnSinavId.Value;
                window2.VisibleOnPageLoad = true;
                window2.Modal = true;
                window2.DestroyOnClose = true;
                window2.VisibleStatusbar = false;
                window2.Width = 1000;
                window2.Height = 650;
                window2.EnableViewState = false;
                RadWindowManager1.Windows.Add(window2);
            }
            else
                ShowMesaj("Lütfen Soru Seçmeden önce Sınavı Kaydediniz");
        }

        private bool CheckValues()
        {
            if (txtSinavSure.Text == "")
            {
                ShowMesaj("Sınavın Süresinin Girilmesi Zorunludur");
                return false;
            }
            if (txtSinavAdi.Text == "")
            {
                ShowMesaj("Lütfen Sınavı Adını Giriniz");
                return false;
            }
            return true;
        }

        private void ShowMesaj(string Mesaj)
        {
            RadNotification1.Text = Mesaj;
            RadNotification1.Show();
        }


        protected void RadAjaxManager1_AjaxRequest(object sender, AjaxRequestEventArgs e)
        {
            if (e.Argument == "Rebind")
            {
                if ((hdnSinavId.Value != "") && (hdnSinavId.Value != "0"))
                {
                    int sinavId = Convert.ToInt32(hdnSinavId.Value);
                    FillForm(sinavId);
                }
            }
        }

        protected void chkGenelSinav_CheckedChanged(object sender, EventArgs e)
        {
            RadWindowManager1.Windows.Clear();
            if (chkGenelSinav.Checked)
            {
                rdcmbOgretmenOnayliDersler.SelectedIndex = -1;
                rdcmbOgretmenOnayliDersler.Enabled = false;
            }
            else
            {
                rdcmbOgretmenOnayliDersler.Enabled = true;
            }
        }

    }
}