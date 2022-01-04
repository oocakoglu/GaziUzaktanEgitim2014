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
    public partial class SoruHazirlama : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }


        protected void RadListView1_ItemDataBound(object sender, Telerik.Web.UI.RadListViewItemEventArgs e)
        {
            Control cntrol = ((Label)e.Item.FindControl("SoruLabel"));
            if (cntrol != null)
            {
                int CvpSayi = Convert.ToInt32(((Label)e.Item.FindControl("CvpSayisiLabel")).Text);
                ((Label)e.Item.FindControl("CvpSayisiLabel")).Visible = false;
                for (int i = 1; i <= CvpSayi; i++)
                {
                    ListItem li = new ListItem(((Label)e.Item.FindControl("Cvp" + i.ToString() + "Label")).Text, "Cvp" + i.ToString());
                    ((RadioButtonList)e.Item.FindControl("rblCvp")).Items.Add(li);
                    ((Label)e.Item.FindControl("Cvp" + i.ToString() + "Label")).Visible = false;
                }
            }
        }

        protected void btnInitInsert_Click(object sender, System.EventArgs e)
        {
            RadListView1.ShowInsertItem();
            RadListView1.FindControl("btnInitInsert").Visible = false;

        }

        protected void btnResimYukle_Click(object sender, System.EventArgs e)
        {
            RadButton button = sender as RadButton;
            RadListViewDataItem Item = button.Parent as RadListViewDataItem;

            FileUpload flupldResim = ((FileUpload)Item.FindControl("flupldResim"));
            if (flupldResim.HasFile)
            {
                String KayitYeri = "";
                KayitYeri = DateTime.Now.ToString();
                KayitYeri = KayitYeri.Replace(" ", "").Replace(":", "").Replace(".", "");
                string SaveLocation = Server.MapPath("Resim") + "\\" + "Soru" + KayitYeri + ".jpg";

                try
                {                        
                    flupldResim.PostedFile.SaveAs(SaveLocation);
                    ((Image)Item.FindControl("imgSoruResim")).ImageUrl = "Resim\\Soru" + KayitYeri + ".jpg";
                    ((TextBox)Item.FindControl("txtResimYol")).Text = "Resim\\Soru" + KayitYeri + ".jpg"; 
                    //ImgProfilResim.ImageUrl = "Resim\\Foto" + KayitYeri + ".jpg";
                    //hdnResimUrl.Value = "Resim\\Foto" + KayitYeri + ".jpg";
                }
                catch
                { }
            }          
        }

        protected void btnResimSil_Click(object sender, System.EventArgs e)
        {
            RadButton button = sender as RadButton;
            RadListViewDataItem Item = button.Parent as RadListViewDataItem;
            string Dosya = MapPath(".") + "\\" + ((TextBox)Item.FindControl("txtResimYol")).Text;

            FileInfo TheFile = new FileInfo(Dosya);
            if (TheFile.Exists)
            {
                File.Delete(Dosya);
            } 

            ((Image)Item.FindControl("imgSoruResim")).ImageUrl = "";
            ((TextBox)Item.FindControl("txtResimYol")).Text = ""; 
        }

    }
}