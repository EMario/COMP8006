/////////////////////////////////////////////////////////////////////////////
//
//	Author: Mario Enriquez
//
//	Id: A00909441
//
//	C8006
//
//	Assignment 3
//
/////////////////////////////////////////////////////////////////////////////

import java.io.*;
import java.util.*;
import java.text.*;

//Class that contains the log data
class logfile{
  public static class LogData {
    public String ipAddr;
    public int tries;
    public String isBanned;
    public String lastTry;

    public LogData(String ipAddr,int tries,String isBanned,String lastTry){
      this.ipAddr=ipAddr;
      this.tries=tries;
      this.isBanned=isBanned;
      this.lastTry=lastTry;
    }
  }

//Class that will contain the secure log data
  public static class NewData {
    public String ipAddr;
    public String status;
    public String date;

    public NewData(String ipAddr,String status,String date){
      this.ipAddr=ipAddr;
      this.status=status;
      this.date=date;
    }
  }

  //Class that translates the month
  public static String getMonth(String month){
    String monthNo="";
    switch(month){
      case "Jan":
                monthNo="01";
                break;
      case "Feb":
                monthNo="02";
                break;
      case "Mar":
                monthNo="03";
                break;
      case "Apr":
                monthNo="04";
                break;
      case "May":
                monthNo="05";
                break;
      case "Jun":
                monthNo="06";
                break;
      case "Jul":
                monthNo="07";
                break;
      case "Aug":
                monthNo="08";
                break;
      case "Sep":
                monthNo="09";
                break;
      case "Oct":
                monthNo="10";
                break;
      case "Nov":
                monthNo="11";
                break;
      case "Dec":
                monthNo="12";
                break;
    }
    return monthNo;
  }

  @SuppressWarnings("deprecation")
  public static void main (String args[]){
    try{
      String secure_path="",log_path="",config_path,logDate,lastCheck,aux,month,split[],splitaux[],banTime="",cooldownTime="";
      int i,j,index,operation_time,attempts=0,multi_attempts=0;
      long ban=0,cooldown=0,k;
      ArrayList<String> search_terms = new ArrayList<String>();
      ArrayList<LogData> log_entries = new ArrayList<LogData>();
      ArrayList<NewData> sec_entries = new ArrayList<NewData>();
      DateFormat dateFormat = new SimpleDateFormat("MM/dd HH:mm:ss");
      Date date,curDate;
      File f,sec,config;
      FileReader fr;
      FileWriter fw;
      BufferedReader br;
      BufferedWriter bw;
      config_path=args[0];
      curDate=new Date();
      config=new File(config_path);
	  //Obtain all the values of the config file and assign them into variables
      if(config.exists() && !config.isDirectory()){
        fr=new FileReader(config);
        br=new BufferedReader(fr);
        while((aux = br.readLine()) != null ){
          if(aux.contains(" = ")){
            split=aux.split(" = ");
            switch (split[0]){
              case "SEC_PATH":
                secure_path=split[1];
                break;
              case "LOG_PATH":
                log_path=split[1];
                break;
              case "MAX_ATT":
                attempts=Integer.parseInt(split[1]);
                break;
              case "MULT_ATT":
                multi_attempts=Integer.parseInt(split[1]);
                break;
              case "BAN_TIME":
                banTime=split[1];
                break;
              case "COOLDOWN":
                cooldownTime=split[1];
                break;
              case "PROTOCOL":
                search_terms.add(split[1]);
                break;
              case "SEARCHTERM":
                search_terms.add(split[1]);
                break;
            }
          }
        }
        br.close();
        fr.close();
      }
      f = new File(log_path);
	  //Read the log which contains the current Ips registered
      if(f.exists() && !f.isDirectory()) {
        fr=new FileReader(f);
        br=new BufferedReader(fr);
        while((aux = br.readLine()) != null ){
          split=aux.split(" - ");
          log_entries.add(new LogData(split[0],Integer.parseInt(split[1]),split[2],split[3]));
			  }
        br.close();
        fr.close();
      } else {
        f.createNewFile();
        lastCheck="";
      }
      sec = new File(secure_path);
      fr=new FileReader(sec);
      br=new BufferedReader(fr);
	  //Read the secure log and discard any entry that is not usefule
      while((aux = br.readLine()) != null ){
        if(aux.contains(search_terms.get(0)) && aux.contains(search_terms.get(1))){
          aux=aux.replace("  "," ");
          split=aux.split(" ");
          splitaux=split[2].split(":");
          month=getMonth(split[0]);
          date = new Date(2016-1900,Integer.parseInt(month)-1,Integer.parseInt(split[1]),Integer.parseInt(splitaux[0]),Integer.parseInt(splitaux[1]),Integer.parseInt(splitaux[2]));
          logDate=""+(date.getTime());
          sec_entries.add(new NewData(split[10],split[5],logDate));
        }
      }
	  //Check for new entries into the IP registry, if the IP is not found add it
	  //if its found check if its an succesful or unsuccesful login in addition
	  //if its a new entry
      for(i=0;i<sec_entries.size();i++){
        index=-1;
        for(j=0;j<log_entries.size();j++){
          if(sec_entries.get(i).ipAddr.equals(log_entries.get(j).ipAddr)){
            index=j;
          }
        }
        if(sec_entries.get(i).status.equals("Failed")){
          if(index>=0){
            if(Long.parseLong(sec_entries.get(i).date) > Long.parseLong(log_entries.get(index).lastTry)){
              log_entries.get(index).lastTry=sec_entries.get(i).date;
              log_entries.get(index).tries++;
            }
          } else {
            log_entries.add(new LogData(sec_entries.get(i).ipAddr,1,"No",sec_entries.get(i).date));
          }
        } else {
          if(index>=0){
            if(Long.parseLong(sec_entries.get(i).date) > Long.parseLong(log_entries.get(index).lastTry)){
              log_entries.get(index).lastTry=sec_entries.get(i).date;
              log_entries.get(index).tries=0;
            }
          }
        }
      }
      br.close();
      fr.close();
      fw=new FileWriter(f,false);
      bw=new BufferedWriter(fw);
	  //update the ip log registry
      for(j=0;j<log_entries.size();j++){
        if(!banTime.equals("0") && log_entries.get(j).tries>=attempts){
          k=Long.parseLong(banTime);
          ban=Long.parseLong(log_entries.get(j).lastTry)+k;
          if((curDate.getTime()) > ban){
            log_entries.get(j).tries=0;
          }
        }
        if(!cooldownTime.equals("0") && (log_entries.get(j).tries<attempts)){
          k=Long.parseLong(cooldownTime);
          cooldown=Long.parseLong(log_entries.get(j).lastTry)+k;
          if((curDate.getTime()) > cooldown){
            log_entries.get(j).tries=0;
          }
        }
        if(log_entries.get(j).tries>=attempts){
          log_entries.get(j).isBanned="Yes";
        } else {
          log_entries.get(j).isBanned="No";
        }
        bw.write(log_entries.get(j).ipAddr + " - " + log_entries.get(j).tries + " - " + log_entries.get(j).isBanned + " - " + log_entries.get(j).lastTry + "\n");
      }
      bw.close();
      fw.close();
  } catch (Exception e){
    System.out.println(e);
  }
  }
}
