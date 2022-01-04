using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using Telerik.Web.UI;

namespace GaziProje2014.Forms
{
    public partial class OgrenciSinav : System.Web.UI.Page
    {
        protected void CikisButton_Click(object sender, ImageClickEventArgs e)
        {
            Session.Remove("KullaniciAdi");
            Session.Remove("KullaniciId");
            Session.Remove("KullaniciTipiId");
            Session.Remove("SkinName");
            Session.Remove("BackGround");


            //Response.Redirect("~/Login.aspx");
            //Response.Redirect("~/HizliGiris.aspx");
            Response.Redirect("~/HizliGiris.aspx");
        }

        protected void QsfSkinManager_SkinChanged(object sender, SkinChangedEventArgs e)
        {
            GAZIEntities gaziEntities = new GAZIEntities();
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            Kullanicilar kullanici = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == kullaniciId).FirstOrDefault();
            kullanici.SkinName = e.Skin;
            gaziEntities.SaveChanges();

            Session.Add("SkinName", e.Skin);
        }

        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            string backGround = "background: url(/Style/Images/ArkaPlan2.jpg) no-repeat center center fixed;";
            if (Session["BackGround"] != null)
            {
                backGround = Session["BackGround"].ToString();
                backGround = "background: url(" + backGround + ") no-repeat center center fixed;";
            }

            HtmlGenericControl itemStyle = new HtmlGenericControl("style");
            itemStyle.Attributes.Add("type", "text/css");
            itemStyle.InnerHtml = "html "
                                + "{"
                //+ "background: url(/Style/Images/ArkaPlan2.jpg) no-repeat center center fixed;"
                                + backGround
                                + "-webkit-background-size: cover;"
                                + "-moz-background-size: cover;"
                                + "-o-background-size: cover;"
                                + "background-size: cover;"
                                + "height: 100%;"
                                + "}";
            Page.Header.Controls.Add(itemStyle);

            //Control cnt = Master.FindControl("masterpageBody");
            //cnt
            //.Attributes.Add("style", "background-color: 2e6095");

            if (Session["SkinName"] != null)
                QsfSkinManager.Skin = Session["SkinName"].ToString();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["SinavId"] != null)
            {
                hdnOgrenciSinavId.Value = Session["SinavId"].ToString();
                int sinavId = Convert.ToInt32(hdnOgrenciSinavId.Value);

                if (!IsPostBack)
                {
                    SinavYukle(sinavId);
                }
                SinavSureGetir(sinavId);      
            }
        }

        private void SinavSureGetir(int SinavId)
        {
            GAZIEntities gaziEntities = new GAZIEntities();
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            Data.OgrenciSinav ogrenciSinav = gaziEntities.OgrenciSinav.Where(q => q.SinavId == SinavId && q.OgrenciId == kullaniciId).FirstOrDefault();
         
            if (ogrenciSinav != null)
            {
                TimeSpan sonuc = ogrenciSinav.BitisZamani.Value.AddMinutes(1) - DateTime.Now;
                int kalanSure = sonuc.Minutes;

                if (kalanSure > 0)
                {
                    lblBilgilendirme.Text = kalanSure.ToString() + " dakika";

                    var BasZaman = ogrenciSinav.BaslamaZamani.Value.ToString("H:mm");
                    lblBaslangicTarihi.Text = BasZaman;
                    var BitZaman = ogrenciSinav.BitisZamani.Value.ToString("H:mm");
                    lblBitisTarihi.Text = BitZaman;                  
               }
               else
               {
                   int Cevap = gaziEntities.OgrenciSinavDetay.Where(q => q.OgrenciSinavId == ogrenciSinav.OgrenciSinavId).Count();
                     
                   //** Zaten Bitmiş  
                   if (Cevap > 0)
                   {
                       Response.Redirect("~/Forms/OgrenciGecmisSinavlar.aspx");
                   }
                   else
                   {
                       btnSinaviBitir_Click(null, null);
                   }                    
                }
            }
            else
            {
                SinavaBasla(SinavId);
                SinavSureGetir(SinavId);
            }
        }

        private void SinavaBasla(int SinavId)
        {
            GAZIEntities gaziEntities = new GAZIEntities();
            Data.Sinav sinav = gaziEntities.Sinav.Where(q => q.SinavId == SinavId).FirstOrDefault();
            int sinavSure = sinav.Sure.Value;
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());

            Data.OgrenciSinav ogrenciSinav = new Data.OgrenciSinav();
            ogrenciSinav.SinavId = SinavId;
            ogrenciSinav.BaslamaZamani = DateTime.Now;
            ogrenciSinav.BitisZamani = DateTime.Now.AddMinutes(sinavSure);
            ogrenciSinav.OgrenciId = kullaniciId;

            ogrenciSinav.SonGuncellemeTarihi = DateTime.Now;
            gaziEntities.OgrenciSinav.Add(ogrenciSinav);
            gaziEntities.SaveChanges();

            //** Panele Yazılar Yazılıyor
            var BasZaman = DateTime.Now.ToString("H:mm");
            lblBaslangicTarihi.Text = BasZaman;
            var BitZaman = DateTime.Now.AddMinutes(sinavSure).ToString("H:mm");
            lblBitisTarihi.Text = BitZaman;
        }

        private void SinavYukle(int SinavId)
        {
            GAZIEntities gaziEntities = new GAZIEntities();
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
            Control cntrol = ((Label)e.Item.FindControl("lblSoruIcerik"));
            if (cntrol != null)
            {
                int CvpSayi = Convert.ToInt32(((Label)e.Item.FindControl("lblCvpSayisi")).Text);
                int dogruCvp = Convert.ToInt32(((Label)e.Item.FindControl("lblDogruCvp")).Text);

                //((Label)e.Item.FindControl("CvpSayisiLabel")).Visible = false;
                for (int i = 1; i <= CvpSayi; i++)
                {
                    ListItem li = new ListItem(((Label)e.Item.FindControl("Cvp" + i.ToString() + "Label")).Text, i.ToString());
                    //li.Enabled = false;
                    //if (i == dogruCvp)
                    //    li.Selected = true;

                    ((RadioButtonList)e.Item.FindControl("rblCvp")).Items.Add(li);
                    ((Label)e.Item.FindControl("Cvp" + i.ToString() + "Label")).Visible = false;
                }
            }
        }

        protected void timer1_tick(object sender, EventArgs e)
        {
            int sinavId = Convert.ToInt32(hdnOgrenciSinavId.Value);
            SinavSureGetir(sinavId);
        }

        protected void btnSinaviBitir_Click(object sender, EventArgs e)
        {
            //OgrenciSinavDetayId            
            GAZIEntities gaziEntities = new GAZIEntities();

            //** OgrenciSinavId
            int sinavId = Convert.ToInt32(hdnOgrenciSinavId.Value);
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            Data.OgrenciSinav ogrenciSinav = gaziEntities.OgrenciSinav.Where(q => q.SinavId == sinavId && q.OgrenciId == kullaniciId).FirstOrDefault();
            ogrenciSinav.BitisZamani = DateTime.Now;
            
            
            foreach (var item in RadListView1.Items)
            {
                Label cntrol = ((Label)item.FindControl("SoruId"));
                if (cntrol != null)
                {
                    OgrenciSinavDetay ogrenciSinavDetay = new OgrenciSinavDetay();

                    ogrenciSinavDetay.OgrenciSinavId = ogrenciSinav.OgrenciSinavId;
                    ogrenciSinavDetay.SoruId = Convert.ToInt32(cntrol.Text);

                    int ogrenciCvp = 0;
                    RadioButtonList radioButtonList = ((RadioButtonList)item.FindControl("rblCvp"));
                    if (radioButtonList.SelectedValue != "")
                        ogrenciCvp = Convert.ToInt32(radioButtonList.SelectedValue);

                    ogrenciSinavDetay.OgrenciCvp = ogrenciCvp;
                    gaziEntities.OgrenciSinavDetay.Add(ogrenciSinavDetay);
                }
            }
            
            gaziEntities.SaveChanges();
            SinavSureGetir(sinavId);
        } 
    }
}