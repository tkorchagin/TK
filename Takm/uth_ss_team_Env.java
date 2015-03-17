// Environment code for project Loco.mas2j
import jason.asSyntax.*;
import jason.environment.*;
import java.util.logging.*;
import java.io.*;
import java.util.*;
import java.lang.*;
import java.math.*;

public class uth_ss_team_Env extends Environment {
	
    private Logger logger = Logger.getLogger("uth_ss_team" + ".mas2j." + uth_ss_team_Env.class.getName());
	
	private Integer perceptsDisabled = new Integer(0);
	

	FileReader FReader;
	BufferedReader BufReader;
	PrintWriter writer;
    BufferedWriter BufWriter;
	FileWriter FWriter;
	
	
	protected static Term enable_percepts = Literal.parseLiteral("enable_percepts");
    protected static Term disable_percepts = Literal.parseLiteral("disable_percepts");
    protected static boolean envIsOk = false;
	protected int endCounter = 0;
	
	protected int Debug_mode = 0;

    /** Called before the MAS execution with the args informed in .mas2j */

    @Override

    public void init(String[] args) {

        super.init(args);

        // LoadFromFile("data/uth_ss_team/input/uth_ss_team_input.txt");
        LoadFromFile("./uth_ss_team_input.txt"); // TK
		updatePercepts();
		
    }

	
	java.awt.event.ActionListener listener = null;

	public void addActionListener(java.awt.event.ActionListener l) {
		listener = l;
	}
	
	public void actionPerformed(java.awt.event.ActionEvent event) {
		if (listener != null) {
			listener.actionPerformed(event);
		}
	}

	Structure lastAct = null;

	public Structure getLastAct() {
		return lastAct;
	}
	
	public void enablePercepts() {
		synchronized (perceptsDisabled) {
			if (perceptsDisabled > 0)
				perceptsDisabled--;
		}
	}

	public void disablePercepts() {
		synchronized (perceptsDisabled) {
			perceptsDisabled++;
		}
	}
	
	public java.util.List<Literal> getPercepts(java.lang.String agName)	{
		synchronized (perceptsDisabled) {
			if (perceptsDisabled == 0)
				return super.getPercepts(agName);
		}
		return null;
	}

	
	private void updatePercepts() {
	}

	
	public void debug(int i) {
		logger.info(Integer.toString(i));
	}
		
	
    @Override

    public boolean executeAction(String agName, Structure action) {

        boolean res = false;
		if (action.equals(enable_percepts)) {
			enablePercepts();
			res = true;
        } else if (action.equals(disable_percepts)) {
			disablePercepts();
			res = true;
		} else if (action.getTerm(0).toString().contains("plan_begin")) {
			// String filename = "data/uth_ss_team/output/team_tell_output.txt";
			String filename = "./team_tell_output.txt"; // TK
			try {
				File file = new File(filename);
				FWriter = new FileWriter(file);
				BufWriter = new BufferedWriter(FWriter);
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}			
		}  else if (action.getTerm(0).toString().contains("plan_end")) {
			try {
				BufWriter.close();
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("set_debug_mode")) {
			Debug_mode = 1;
			res = true;			
		}  else if (action.getFunctor().contains("tell")) {
			//if (Debug_mode == 1) logger.info(action.getTerm(0).toString());
			String terminator = "\r\n";
			String line = action.getTerm(0).toString() + terminator;
			try {
				BufWriter.write(line);
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("start_writing")) {
			// String filename = "data/uth_ss_team/output/" + action.getTerm(0).toString()+".csv";
			String filename = "./" + action.getTerm(0).toString()+".csv"; // TK

			try {
				File file = new File(filename);
				FWriter = new FileWriter(file);
				BufWriter = new BufferedWriter(FWriter);
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("end_writing")) {
			try {
				BufWriter.close();
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("write_next")) {  
			// Parsing of loco input data and transforming them into Jason format
			String terminator;
			if(action.getFunctor().contains("line")) 
				terminator = "\r\n";
			else
				terminator = "; ";
			String line = action.getTerm(0).toString() + terminator;
					line = line.replace(',',';');			// -----//-----//-----//-----//----
					line = line.replace('.',',');			// two lines needed if csv in prepared in the russian format
			try {
				BufWriter.write(line);
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("start_loading")) {
			String s = action.getTerm(0).toString();
			String inputFile = s.substring(1,s.length()-1);		// get rid of quotes
			
											// the first term must be the name (w/o extention)
			try {													// of the csv-file
				FReader = new FileReader(inputFile);
				BufReader = new BufferedReader(FReader);
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("end_loading")) {
			try {
				BufReader.close();
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("load_team")) {  
			// Parsing of team input data and transforming them into Jason format
			String line,fact,name,mode;
			String agent = action.getTerm(0).toString();
			String[] args;
			int i;
			try {
				if ((line = BufReader.readLine()) != null)	{			
					line = line.replace(',','.');			// two lines needed if csv in prepared in the russian format 
					line = line.replace(';',',');			// -----//-----//-----//-----//----
					line = line.replaceAll("[ ]+","");		// -----//-----//-----//-----//----
					args = line.split(",");  
					if(args[0].length() !=0) {
						mode = args[2];
						if(mode.equals("work")) 
							fact = "team(id(" + args[0] + "),depot(" + args[1] 
								+ "),work(will_work(" + args[3] + "),will_rest(" 
								+ args[4] + ")),state(min_rest(" + args[5] 
								+ "),work_nights(" + args[6] + "),overtime(" 
								+ args[7] + ")))";
						else if (mode.equals("rest")) 
							fact = "team(id(" + args[0] + "),depot(" + args[1] 
								+ "),rest(past_rest(" + args[3] + "),will_rest(" 
								+ args[4] + ")),state(min_rest(" + args[5] 
								+ "),work_nights(" + args[6] + "),overtime(" 
								+ args[7] + ")))";
						else if (mode.equals("vacation")) 
							fact = "team(id(" + args[0] + "),depot(" + args[1] 
								+ "),vacation(will_rest(" + args[3] 
								+ ")),state(min_rest(" + args[4] 
								+ "),work_nights(" + args[5] + "),overtime(" 
								+ args[6] + ")))";
						else  
							logger.info("Error for team id(" + args[0] 
									+ "). Unrecognized mode: " + mode);
							fact = "";
						addPercept(agent, Literal.parseLiteral(fact));
						res = true;
					} else 
						res = false; 
				} else  
					res = false;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("load_depot")) {  
			// Parsing of loco input data and transforming them into Jason format
			String line,fact;
			String agent = action.getTerm(0).toString();
			String[] args;
			try {
				if ((line = BufReader.readLine()) != null)	{			
					args = line.split("[;]");  // from CSV file in Russian delimiter is ";"
// depot (id(Id), period(from(BeginHour),to(EndHour)), norm(Norm), service_type(SType))					
					if(args[0].length() !=0) {
						fact = "depot(id(" + args[0] + "),norm(" 
							+ args[1]  + "),night_start(" + args[2] +  "))";
						addPercept(agent, Literal.parseLiteral(fact));
						res = true;
					} else 
						res = false; 
				} else  
					res = false;
				
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("load_distance")
				| action.getFunctor().contains("load_station")) {  
			// Parsing of loco input data and transforming them into Jason format
			String line,fact;
			String agent = action.getTerm(0).toString();
			String act = action.getFunctor();
			String[] args;
			try {
				if ((line = BufReader.readLine()) != null)	{			

					line = line.replace(',','.');			// two lines needed if csv in prepared in the russian format 
					line = line.replace(';',',');			// -----//-----//-----//-----//----
					line = line.replaceAll("[ ]+","");		// -----//-----//-----//-----//----
					args = line.split(",");  


					if(args[0].length() !=0) {
						if(act.contains("load_distance")) {
							fact = "duration(track(station(" + args[0] + "),station(" + args[1]  + ")),"
										+ args[2] +  ")";
						} else {
							fact = "station(" + args[0] + ",belongs(" + args[1]  + ","
								+ args[2] + "," + args[3]  + "," + args[4] + "))";
						}
						addPercept(agent, Literal.parseLiteral(fact));
						res = true;
					} else 
						res = false; 
				} else  
					res = false;
				
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} 
		updatePercepts();
		return res;
    }
	
	private void LoadFromFile(String fileName) {
		String line;				
		try {
			FileReader fr = new FileReader(fileName);
			BufferedReader br = new BufferedReader(fr);
			while ((line = br.readLine()) != null) {				
				String msg = line.substring(1);	
				if (line.charAt(0) == '+') {
					addPercept("uth_ss_team_main", Literal.parseLiteral(msg));
				} else {
					removePercept("uth_ss_team_main", Literal.parseLiteral(msg));
				}
			}
			br.close();
		} catch(Exception e) {
			System.out.println(e);
		}
	}
}
