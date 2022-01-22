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
    public partial class SinavSoruSecim : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                //Session.Add("KullaniciAdi", "sssss");
                //Session.Add("KullaniciId", 87);
                //Session.Add("KullaniciTipiId", 14);
                //Session["OgretmenDersId"] = 27;

                rdDersler.DataSource = Common.GetDersler();
                rdDersler.DataTextField = "OgretmenDersAdi";
                rdDersler.DataValueField = "OgretmenDersId";
                rdDersler.DataBind();
                                
                if (Session["OgretmenDersId"] != null)
                {
                    int ogretmenDersId = Convert.ToInt32(Session["OgretmenDersId"].ToString());
                    rdDersler.SelectedValue = ogretmenDersId.ToString();                    
                }
                else
                {
                    rdDersler.SelectedIndex = 0;
                }
                rdDersler_SelectedIndexChanged(null, null);
            }
        }

        private  void  grdSorularBind()
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

        protected void btnTamam_Click(object sender, EventArgs e)
        {
            int sinavId = Convert.ToInt32(Request.QueryString["SinavId"]);
            GAZIDbContext gaziEntities = new GAZIDbContext();

            foreach (GridDataItem item in grdSorular.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["chkTemplateColumn"].FindControl("chksoruSec");
                if (chk.Checked)
                {
                    int soruId = Convert.ToInt32(item["SoruId"].Text);
                    
                    int KayitSayi = gaziEntities.SinavDetay.Where(q => q.SinavId == sinavId && q.SoruId == soruId).Count();
                    if (KayitSayi == 0)
                    {
                        Data.Models.SinavDetay sinavDetay = new Data.Models.SinavDetay();
                        sinavDetay.SoruId = soruId;
                        sinavDetay.SinavId = sinavId;
                        gaziEntities.SinavDetay.Add(sinavDetay);
                    }
                }
            }
            gaziEntities.SaveChanges();
            ClientScript.RegisterStartupScript(Page.GetType(), "mykey", "CloseAndRebind();", true);
        }

        protected void btnIptal_Click(object sender, EventArgs e)
        {
            ClientScript.RegisterStartupScript(Page.GetType(), "mykey", "CancelEdit();", true);
        }
    }
}