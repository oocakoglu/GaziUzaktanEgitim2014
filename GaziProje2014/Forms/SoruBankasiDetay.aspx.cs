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
    public partial class SoruBankasiDetay : System.Web.UI.Page
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
                    int ogretmenDersId = Convert.ToInt32(Session["SinavOgretmenDersId"].ToString());
                    rdDersler.SelectedValue = ogretmenDersId.ToString();
                    rdDersler_SelectedIndexChanged(null, null);
                }
            }
        }

        protected void rdDersler_SelectedIndexChanged(object sender, RadComboBoxSelectedIndexChangedEventArgs e)
        {
            if (rdDersler.SelectedValue != "")
            {
                int ogretmenDersId = Convert.ToInt32(rdDersler.SelectedValue);
                GAZIDbContext gaziEntities = new GAZIDbContext();
                var sorular = gaziEntities.Sorular.Where(q => q.OgretmenDersId == ogretmenDersId).ToList();

                rdListSorular.DataSource = sorular;
                rdListSorular.DataBind();
            }
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
                    ListItem li = new ListItem(((Label)e.Item.FindControl("Cvp" + i.ToString() + "Label")).Text, "Cvp" + i.ToString());
                    li.Enabled = false;
                    if (i == dogruCvp)
                        li.Selected = true;

                    ((RadioButtonList)e.Item.FindControl("rblCvp")).Items.Add(li);
                    ((Label)e.Item.FindControl("Cvp" + i.ToString() + "Label")).Visible = false;
                }
            }
        }

        protected void btnYeniSoru_Click(object sender, EventArgs e)
        {
                string ogretmenDersId = rdDersler.SelectedValue;
                Session.Add("SoruOgretmenDersId", ogretmenDersId);
                Response.Redirect("~/Forms/SoruDetay.aspx");
           
        }

        protected void btnSoruDuzenle_Click(object sender, System.EventArgs e)
        {
            RadButton button = sender as RadButton;
            RadListViewDataItem Item = button.Parent as RadListViewDataItem;
            Label lblSoruId = ((Label)Item.FindControl("lblSoruId"));
            int soruId = Convert.ToInt32(lblSoruId.Text);
            string soruOgretmenDersId = rdDersler.SelectedValue;

            Session.Add("SoruId", soruId);
            Session.Add("SoruOgretmenDersId", soruOgretmenDersId);
            Response.Redirect("~/Forms/frmSoruDetay.aspx");
        }

        protected void btnGeri_Click(object sender, EventArgs e)
        {
            Session.Remove("SinavOgretmenDersId");       
            Response.Redirect("~/Forms/SoruBankasi.aspx");
        }

    }
}