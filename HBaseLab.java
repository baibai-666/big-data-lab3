import java.util.*;
import org.apache.hadoop.hbase.*;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;

public class HBaseLab implements AutoCloseable {
 final Connection c=ConnectionFactory.createConnection(HBaseConfiguration.create());
 HBaseLab() throws Exception {}
 static byte[] b(String s){return Bytes.toBytes(s);}
 static TableName tn(String s){if(!s.startsWith("lab3_"))throw new IllegalArgumentException("Lab tables only");return TableName.valueOf(s);}
 public void createTable(String name,String[] fields)throws Exception{
  try(Admin a=c.getAdmin()){
   TableName t=tn(name);if(a.tableExists(t)){if(a.isTableEnabled(t))a.disableTable(t);a.deleteTable(t);}
   TableDescriptorBuilder d=TableDescriptorBuilder.newBuilder(t);
   Set<String> fs=new TreeSet<>();for(String f:fields)fs.add(f.split(":",2)[0]);
   for(String f:fs)d.setColumnFamily(ColumnFamilyDescriptorBuilder.of(f));a.createTable(d.build());
  }
 }
 public void addRecord(String name,String row,String[] fields,String[] values)throws Exception{
  if(fields.length!=values.length)throw new IllegalArgumentException("Length mismatch");
  Put p=new Put(b(row));for(int i=0;i<fields.length;i++){String[] f=fields[i].split(":",2);p.addColumn(b(f[0]),b(f.length==2?f[1]:"value"),b(values[i]));}
  try(Table t=c.getTable(tn(name))){t.put(p);}
 }
 public void scanColumn(String name,String column)throws Exception{
  String[] f=column.split(":",2);
  // Scan all rows so rows missing this column can explicitly produce null.
  try(Table t=c.getTable(tn(name));ResultScanner rs=t.getScanner(new Scan())){
   for(Result r:rs){System.out.print(Bytes.toString(r.getRow())+" "+column+" ");
    if(f.length==2){byte[] v=r.getValue(b(f[0]),b(f[1]));System.out.println(v==null?"null":Bytes.toString(v));}
    else{NavigableMap<byte[],byte[]> m=r.getFamilyMap(b(f[0]));if(m==null||m.isEmpty())System.out.println("null");else{for(Map.Entry<byte[],byte[]> e:m.entrySet())System.out.print(Bytes.toString(e.getKey())+"="+Bytes.toString(e.getValue())+" ");System.out.println();}}
   }
  }
 }
 public void modifyData(String name,String row,String column)throws Exception{
  String value=System.getProperty("lab3.newValue");if(value==null)throw new IllegalArgumentException("Set -Dlab3.newValue");modifyData(name,row,column,value);
 }
 public void modifyData(String name,String row,String column,String value)throws Exception{addRecord(name,row,new String[]{column},new String[]{value});}
 public void deleteRow(String name,String row)throws Exception{try(Table t=c.getTable(tn(name))){t.delete(new Delete(b(row)));}}
 public void scanAll(String name)throws Exception{
  try(Table t=c.getTable(tn(name));ResultScanner rs=t.getScanner(new Scan())){
   for(Result r:rs)for(Cell cell:r.rawCells())System.out.println(name+" "+Bytes.toString(r.getRow())+" "+Bytes.toString(CellUtil.cloneFamily(cell))+":"+Bytes.toString(CellUtil.cloneQualifier(cell))+"="+Bytes.toString(CellUtil.cloneValue(cell)));
  }
 }
 long count(String name)throws Exception{long n=0;try(Table t=c.getTable(tn(name));ResultScanner rs=t.getScanner(new Scan())){for(Result r:rs)n++;}return n;}
 String get(String name,String row,String f,String q)throws Exception{try(Table t=c.getTable(tn(name))){return Bytes.toString(t.get(new Get(b(row))).getValue(b(f),b(q)));}}
 void check(boolean ok,String label){if(!ok)throw new AssertionError(label);System.out.println("PASS "+label);}
 public void close()throws Exception{c.close();}
 public static void main(String[] args)throws Exception{try(HBaseLab h=new HBaseLab()){
  h.createTable("lab3_Student",new String[]{"Info","Score"});
  h.createTable("lab3_Course",new String[]{"Info"});h.createTable("lab3_SC",new String[]{"Info"});
  String[][] students={{"Zhangsan","2015001","male","23"},{"Mary","2015002","female","22"},{"Lisi","2015003","male","24"}};
  for(String[] s:students)h.addRecord("lab3_Student",s[0],new String[]{"Info:S_No","Info:S_Sex","Info:S_Age"},new String[]{s[1],s[2],s[3]});
  String[][] courses={{"123001","Math","2.0"},{"123002","Computer Science","5.0"},{"123003","English","3.0"}};
  for(String[] s:courses)h.addRecord("lab3_Course",s[0],new String[]{"Info:C_Name","Info:C_Credit"},new String[]{s[1],s[2]});
  String[][] scores={{"2015001","123001","86","Zhangsan","Math"},{"2015001","123003","69","Zhangsan","English"},{"2015002","123002","77","Mary","Computer Science"},{"2015002","123003","99","Mary","English"},{"2015003","123001","98","Lisi","Math"},{"2015003","123002","95","Lisi","Computer Science"}};
  for(String[] s:scores){h.addRecord("lab3_SC",s[0]+"_"+s[1],new String[]{"Info:Score"},new String[]{s[2]});h.addRecord("lab3_Student",s[3],new String[]{"Score:"+s[4]},new String[]{s[2]});}
  h.check(h.count("lab3_Student")==3&&h.count("lab3_Course")==3&&h.count("lab3_SC")==6,"Student=3 Course=3 SC=6");
  for(String t:new String[]{"lab3_Student","lab3_Course","lab3_SC"})h.scanAll(t);
  for(String[] s:scores)h.check(s[2].equals(h.get("lab3_Student",s[3],"Score",s[4])),"score "+s[3]+" "+s[4]+"="+s[2]);
  h.scanColumn("lab3_Student","Score");h.scanColumn("lab3_Student","Score:Math");
  h.check(h.get("lab3_Student","Mary","Score","Math")==null,"missing Math column returns null");
  h.createTable("lab3_api_demo",new String[]{"Info"});h.addRecord("lab3_api_demo","demo",new String[]{"Info:value"},new String[]{"old"});
  System.setProperty("lab3.newValue","new");h.modifyData("lab3_api_demo","demo","Info:value");h.check("new".equals(h.get("lab3_api_demo","demo","Info","value")),"modifyData");
  try(Admin a=h.c.getAdmin()){
   for(TableDescriptor d:a.listTableDescriptors()){
    List<String> families=new ArrayList<>();for(byte[] f:d.getColumnFamilyNames())families.add(Bytes.toString(f));
    System.out.println("TABLE "+d.getTableName()+" "+families);
   }
   a.addColumnFamily(tn("lab3_api_demo"),ColumnFamilyDescriptorBuilder.of("Extra"));
   h.addRecord("lab3_api_demo","demo",new String[]{"Extra:x"},new String[]{"1"});
   try(Table t=h.c.getTable(tn("lab3_api_demo"))){t.delete(new Delete(b("demo")).addColumns(b("Extra"),b("x")));}
   h.check(h.get("lab3_api_demo","demo","Extra","x")==null,"delete column");
   a.deleteColumnFamily(tn("lab3_api_demo"),b("Extra"));h.check(!a.getDescriptor(tn("lab3_api_demo")).hasColumnFamily(b("Extra")),"delete column family");
   h.scanColumn("lab3_api_demo","Info");h.deleteRow("lab3_api_demo","demo");h.check(h.count("lab3_api_demo")==0,"deleteRow");
   h.addRecord("lab3_api_demo","demo",new String[]{"Info:value"},new String[]{"1"});a.disableTable(tn("lab3_api_demo"));a.truncateTable(tn("lab3_api_demo"),true);h.check(h.count("lab3_api_demo")==0,"truncate table");
  }
  h.createTable("lab3_api_demo",new String[]{"Info"});h.check(h.count("lab3_api_demo")==0,"recreate existing table");
  System.out.println("HBASE JAVA ALL CHECKS PASSED");
 }}
}
