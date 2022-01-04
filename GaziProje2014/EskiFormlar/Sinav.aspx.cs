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
    public partial class Sinav : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void RadListView1_ItemDataBound(object sender, Telerik.Web.UI.RadListViewItemEventArgs e)
        {//padding-top: 30px;
            //if (e.Item is RadListViewDataItem)
            //{
            //    RadListViewDataItem item = e.Item as RadListViewDataItem;               
            //    int SoruId = Convert.ToInt32(item.GetDataKeyValue("SoruId").ToString());

            //    GAZIEntities gaziEntities = new GAZIEntities();
            //    List<SinavCevaplar> sinavCevaplar = gaziEntities.SinavCevaplar.Where(q => q.SoruId == SoruId).ToList();
            //    ((RadioButtonList)e.Item.FindControl("rblCvp")).DataSource = sinavCevaplar;
            //    ((RadioButtonList)e.Item.FindControl("rblCvp")).DataValueField = "CevapId";
            //    ((RadioButtonList)e.Item.FindControl("rblCvp")).DataTextField = "CevapMetni";
            //    ((RadioButtonList)e.Item.FindControl("rblCvp")).DataBind();
            //}
        }

        protected void btnSinaviBitir_Click(object sender, EventArgs e)
        {
            foreach (Telerik.Web.UI.RadListViewItem item in RadListView1.Items)
            {
                string Cevap = ((RadioButtonList)item.FindControl("rblCvp")).SelectedValue;
                if (Cevap == "")
                    Cevap = "0";
                
                int OgrenciCvp = Convert.ToInt32(Cevap);
               // ((Label)e.Item.FindControl("Cvp" + i.ToString() + "Label")).Visible = false;
            }

        }

    }
}