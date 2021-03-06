	using System;
	using System.Linq;
	using System.Reflection;
	
	class FilterableKAttribute : Attribute { }

	class SortableKAttribute : Attribute { }

	
	public class KaseyaObject
	{
		public static PropertyInfo[] GetFilterableParameters(Type t)
		{
			return t.GetProperties().Where(prop => prop.GetCustomAttribute<FilterableKAttribute>() != null).ToArray();
		}
		public static PropertyInfo[] GetSortableParameters(Type t)
		{
			return t.GetProperties().Where(prop => prop.GetCustomAttribute<SortableKAttribute>() != null).ToArray();
		}
	}


public class KAgentProcedure : KaseyaObject 
{
	[FilterableK()]
	public int AgentProcedureId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AgentProcedureName {get; set;}

	[FilterableK()]
	public string Path {get; set;}

	public string Description {get; set;}

	public object Attributes {get; set;}

}

public class KScheduledAgentProcedure : KaseyaObject 
{
	[FilterableK()]
	public int AgentProcedureId {get; set;}

	[FilterableK()]
	public double AgentId {get; set;}

	[FilterableK()]
	public bool ServerTimeZone {get; set;}

	[FilterableK()]
	public bool SkipIfOffLine {get; set;}

	[FilterableK()]
	public bool PowerUpIfOffLine {get; set;}

	public KScriptPrompts ScriptPrompts {get; set;}

	public KRecurrenceOptions Recurrence {get; set;}

	public KDistributionWindow Distribution {get; set;}

	public KStartOptions Start {get; set;}

	public KExclusionWindow Exclusion {get; set;}

	public object Attributes {get; set;}


	public class KScriptPrompt
	{
		public KScriptPrompt(string name, string value,string caption = "")
		{
			Caption = caption;
			Name = name;
			Value = value;
		}
		public string Caption {get; set;}
		public string Name {get; set;}
		public string Value {get; set;}
	}
}

public class KScriptPrompts : KaseyaObject 
{
	public string Caption {get; set;}

	public string Name {get; set;}

	public string Value {get; set;}

}

public class KRecurrenceOptions : KaseyaObject 
{
	public string Repeat {get; set;}

	public int Times {get; set;}

	public string DaysOfWeek {get; set;}

	public string DayOfMonth {get; set;}

	public int SpecificDayOfMonth {get; set;}

	public string MonthOfYear {get; set;}

	public string EndAt {get; set;}

	public string EndOn {get; set;}

	public int EndAfterIntervalTimes {get; set;}

}

public class KDistributionWindow : KaseyaObject 
{
	public string Interval {get; set;}

	public int Magnitude {get; set;}

}

public class KStartOptions : KaseyaObject 
{
	public string StartOn {get; set;}

	public string StartAt {get; set;}

}

public class KExclusionWindow : KaseyaObject 
{
	public string From {get; set;}

	public string To {get; set;}

}

public class KAgentProcedureHistory : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string ScriptName {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime LastExecutionTime {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Status {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Admin {get; set;}

}

public class KAgentProcedurePrompts : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string ScriptName {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime LastExecutionTime {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Status {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Admin {get; set;}

}

public class KServiceDesk : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public double ServiceDeskId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string defaultServDeskDefnFlag {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Prefix {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ServiceDeskName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Description {get; set;}

	[FilterableK()]
	[SortableK()]
	public string EditingTemplate {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DefinationTemplate {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DisplayMachineInfo {get; set;}

	[FilterableK()]
	[SortableK()]
	public string RequiredMachineInfo {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AutoSaveClock {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AutoInsertNote {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AutoInsertHiddenNote {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ShowIncidentNotePan {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ShowWorkOrders {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ShowSessionTimers {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ShowTasks {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AllowDeleteNotes {get; set;}

	[FilterableK()]
	[SortableK()]
	public string TimeZoneOffset {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DefaultPolicy {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DeskAdministrator {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ChangeProcedure {get; set;}

	[FilterableK()]
	[SortableK()]
	public string GoalProcedure {get; set;}

	[FilterableK()]
	[SortableK()]
	public int AotoArchiveTime {get; set;}

	[FilterableK()]
	[SortableK()]
	public string EmailDisplayName {get; set;}

}

public class KTicket : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public double ServiceDeskId {get; set;}

	[FilterableK()]
	[SortableK()]
	public double ServiceDeskTicketId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string TicketRef {get; set;}

	[FilterableK()]
	public string Summary {get; set;}

	[FilterableK()]
	[SortableK()]
	public string TicketStatus {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Stage {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Priority {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Severity {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Category {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Resolution {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Submitter {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Assignee {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Owner {get; set;}

	[FilterableK()]
	public string Organization {get; set;}

	[FilterableK()]
	public string Staff {get; set;}

	public string Phone {get; set;}

	[FilterableK()]
	public double AgentGuid {get; set;}

	[FilterableK()]
	[SortableK()]
	public double InventoryAssetId {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime CreatedDate {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime ModifiedDate {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime LastPublicUpdate {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Closed {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Due {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Promised {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Escalation {get; set;}

	[FilterableK()]
	[SortableK()]
	public string StageGoal {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ResolutionDate {get; set;}

	[FilterableK()]
	[SortableK()]
	public string LockedBy {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime LockedOn {get; set;}

	[FilterableK()]
	[SortableK()]
	public string SourceType {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Policy {get; set;}

	[FilterableK()]
	[SortableK()]
	public string SubmitterEmail {get; set;}

}

public class KTicketStatus : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public double ServiceDeskId {get; set;}

	[FilterableK()]
	[SortableK()]
	public double ServiceDeskTicketId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string TicketRef {get; set;}

	[FilterableK()]
	public string Summary {get; set;}

	[FilterableK()]
	[SortableK()]
	public string TicketStatus {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Stage {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Priority {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Severity {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Category {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Resolution {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Submitter {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Assignee {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Owner {get; set;}

	[FilterableK()]
	public string Organization {get; set;}

	[FilterableK()]
	public string Staff {get; set;}

	public string Phone {get; set;}

	[FilterableK()]
	public double AgentGuid {get; set;}

	[FilterableK()]
	[SortableK()]
	public double InventoryAssetId {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime CreatedDate {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime ModifiedDate {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime LastPublicUpdate {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Closed {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Due {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Promised {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Escalation {get; set;}

	[FilterableK()]
	[SortableK()]
	public string StageGoal {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ResolutionDate {get; set;}

	[FilterableK()]
	[SortableK()]
	public string LockedBy {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime LockedOn {get; set;}

	[FilterableK()]
	[SortableK()]
	public string SourceType {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Policy {get; set;}

	[FilterableK()]
	[SortableK()]
	public string SubmitterEmail {get; set;}

}

public class KAuditSummary : KaseyaObject 
{
	[FilterableK()]
	public double AgentGuid {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DisplayName {get; set;}

	public int TimezoneOffset {get; set;}

	[FilterableK()]
	[SortableK()]
	public string CurrentLogin {get; set;}

	public int AgentType {get; set;}

	[FilterableK()]
	[SortableK()]
	public string RebootTime {get; set;}

	[FilterableK()]
	[SortableK()]
	public string LastCheckinTime {get; set;}

	[FilterableK()]
	[SortableK()]
	public string GroupName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string FirstCheckinTime {get; set;}

	public string TimeZone {get; set;}

	[FilterableK()]
	[SortableK()]
	public int WorkgroupDomainType {get; set;}

	[FilterableK()]
	[SortableK()]
	public string WorkgroupDomainName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ComputerName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DnsComputerName {get; set;}

	public string OsType {get; set;}

	[FilterableK()]
	[SortableK()]
	public string OsInfo {get; set;}

	[FilterableK()]
	[SortableK()]
	public string IpAddress {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Ipv6Address {get; set;}

	[FilterableK()]
	[SortableK()]
	public string SubnetMask {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DefaultGateway {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ConnectionGatewayIp {get; set;}

	[FilterableK()]
	[SortableK()]
	public string GatewayCountry {get; set;}

	[FilterableK()]
	[SortableK()]
	public string MacAddress {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DnsServer1 {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DnsServer2 {get; set;}

	[FilterableK()]
	[SortableK()]
	public int DhcpEnabled {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DhcpServer {get; set;}

	[FilterableK()]
	[SortableK()]
	public int WinsEnabled {get; set;}

	[FilterableK()]
	[SortableK()]
	public string PrimaryWinsServer {get; set;}

	[FilterableK()]
	[SortableK()]
	public string SecondaryWinsServer {get; set;}

	[FilterableK()]
	[SortableK()]
	public string CpuType {get; set;}

	[FilterableK()]
	[SortableK()]
	public int CpuSpeed {get; set;}

	[FilterableK()]
	[SortableK()]
	public int CpuCount {get; set;}

	[FilterableK()]
	[SortableK()]
	public int RamMBytes {get; set;}

	[FilterableK()]
	[SortableK()]
	public int AgentVersion {get; set;}

	[FilterableK()]
	[SortableK()]
	public string LastLoginName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string LoginName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string PrimaryKServer {get; set;}

	[FilterableK()]
	[SortableK()]
	public string SecondaryKServer {get; set;}

	[FilterableK()]
	[SortableK()]
	public string QuickCheckinPeriod {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ContactName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ContactEmail {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ContactPhone {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ContactNotes {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Manufacturer {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProductName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string SystemVersion {get; set;}

	[FilterableK()]
	[SortableK()]
	public string SystemSerialNumber {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ChassisSerialNumber {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ChassisAssetTag {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ExternalBusSpeed {get; set;}

	[FilterableK()]
	[SortableK()]
	public string MaxMemorySize {get; set;}

	[FilterableK()]
	[SortableK()]
	public string MemorySlots {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ChassisManufacturer {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ChassisType {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ChassisVersion {get; set;}

	[FilterableK()]
	[SortableK()]
	public string MotherboardManufacturer {get; set;}

	[FilterableK()]
	[SortableK()]
	public string MotherboardProduct {get; set;}

	[FilterableK()]
	[SortableK()]
	public string MotherboardVersion {get; set;}

	[FilterableK()]
	[SortableK()]
	public string MotherboardSerialNumber {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProcessorFamily {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProcessorManufacturer {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProcessorVersion {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProcessorMaxSpeed {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProcessorCurrentSpeed {get; set;}

	[FilterableK()]
	[SortableK()]
	public int FreeSpace {get; set;}

	[FilterableK()]
	[SortableK()]
	public int UsedSpace {get; set;}

	[FilterableK()]
	[SortableK()]
	public int TotalSize {get; set;}

	[FilterableK()]
	[SortableK()]
	public int NumberOfDrives {get; set;}

}

public class KCredentials : KaseyaObject 
{
	public double CredentialId {get; set;}

	public string Type {get; set;}

	public string Name {get; set;}

	public string UserName {get; set;}

	public string Domain {get; set;}

	public bool CreateAccount {get; set;}

	public bool AsAdministrator {get; set;}

	public bool InEffect {get; set;}

	public object Attributes {get; set;}

}

public class KLocalUserGroup : KaseyaObject 
{
	public string UserGroupName {get; set;}

	public string Description {get; set;}

}

public class KDiskVolume : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string Drive {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Type {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Format {get; set;}

	public int FreeMBytes {get; set;}

	public int UsedMBytes {get; set;}

	public int TotalMBytes {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Label {get; set;}

}

public class KPciAndDisk : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public int TypeId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string TypeName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Vendor {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Product {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Note {get; set;}

}

public class KPrinter : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string PrinterName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Port {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Model {get; set;}

}

public class KLocalGroupMember : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string UserGroupName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string MemberName {get; set;}

}

public class KAddRemovePrograms : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string DisplayName {get; set;}

	public string UninstallString {get; set;}

}

public class KApplication : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string ApplicationName {get; set;}

	public string Description {get; set;}

	public string Version {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Manufacturer {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProductName {get; set;}

	public string DirectoryPath {get; set;}

	public int Size {get; set;}

	[SortableK()]
	public string LastModifiedDate {get; set;}

}

public class KLicense : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string Publisher {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProductName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProductKey {get; set;}

	[FilterableK()]
	[SortableK()]
	public string LicenseCode {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Version {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime InstallationDate {get; set;}

}

public class KSecurityProduct : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string ProductType {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProductName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Manufacturer {get; set;}

	public string Version {get; set;}

	[FilterableK()]
	[SortableK()]
	public KAgentProcedure IsActive {get; set;}

	[FilterableK()]
	[SortableK()]
	public KAgentProcedure IsUpToDate {get; set;}

}

public class KStartupApp : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string AppName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AppCommand {get; set;}

	[FilterableK()]
	[SortableK()]
	public string UserName {get; set;}

}

public class KLocalUserAccount : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string LogonName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string FullName {get; set;}

	public string Description {get; set;}

	public bool IsDisabled {get; set;}

	public bool IsLockedOut {get; set;}

	public bool IsPasswordRequired {get; set;}

	public bool IsPasswordExpired {get; set;}

	public bool IsPasswordChangeable {get; set;}

}

public class KPatchStatus : KaseyaObject 
{
	public int AgentType {get; set;}

	public DateTime LastPatchScanstring {get; set;}

	public DateTime ExecScriptTimestring {get; set;}

	public int RunCount {get; set;}

	public int MonthPeriod {get; set;}

	public int ExecPeriod {get; set;}

	public int RunAtTime {get; set;}

	public int NextPatchScan {get; set;}

	public string NextRunTime {get; set;}

	public int ScheduledScanScriptId {get; set;}

	public int ScheduledScanScriptSchedType {get; set;}

	public int ScanRunAtTime {get; set;}

	public DateTime ScanNextRunTimestring {get; set;}

	public int NewPatchAlert {get; set;}

	public int PatchFailedAlert {get; set;}

	public int InvalidCredentialAlert {get; set;}

	public int WINAUChangedAlert {get; set;}

	public string AlertEmailstring {get; set;}

	public string SourceMachineGuidstring {get; set;}

	public string LanCacheNamestring {get; set;}

	public string PreRebootScriptNamestring {get; set;}

	public string PostRebootScriptNamestring {get; set;}

	public string ScanResultsPendingstring {get; set;}

	public int Reset {get; set;}

	public string RbWarnstring {get; set;}

	public string RebootDaystring {get; set;}

	public string RebootTimestring {get; set;}

	public string NoRebootEmailstring {get; set;}

	public int SourceType {get; set;}

	public string SourcePathstring {get; set;}

	public string SourceLocalstring {get; set;}

	public int DestUseAgentDrive {get; set;}

	public int UseInternetSrcFallback {get; set;}

}

public class KPatch : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public int PatchDataId {get; set;}

	[FilterableK()]
	[SortableK()]
	public int UpdateClassification {get; set;}

	[FilterableK()]
	[SortableK()]
	public int UpdateCategory {get; set;}

	[SortableK()]
	public string KBArticleId {get; set;}

	public string KBArticleLink {get; set;}

	[SortableK()]
	public string SecurityBulletinId {get; set;}

	public string SecurityBulletinLink {get; set;}

	public string UpdateTitle {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime LastPublishedDate {get; set;}

	[FilterableK()]
	[SortableK()]
	public int LocationPending {get; set;}

	public int LocationId {get; set;}

	[SortableK()]
	public string BulletinId {get; set;}

	[FilterableK()]
	[SortableK()]
	public int PatchState {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime InstallDate {get; set;}

	[FilterableK()]
	[SortableK()]
	public int Ignore {get; set;}

	[FilterableK()]
	[SortableK()]
	public int ProductId {get; set;}

	[FilterableK()]
	[SortableK()]
	public int ApprovalStatus {get; set;}

	public string Location {get; set;}

	[FilterableK()]
	[SortableK()]
	public int WuaOverrideFlag {get; set;}

	public string Switches {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProductName {get; set;}

	[FilterableK()]
	[SortableK()]
	public bool IsSuperseded {get; set;}

	[FilterableK()]
	[SortableK()]
	public int WuaProductId {get; set;}

}

public class KAgent : KaseyaObject 
{
	[FilterableK()]
	public double AgentId {get; set;}

	[FilterableK()]
	public int Online {get; set;}

	[FilterableK()]
	public string OSType {get; set;}

	[FilterableK()]
	public string OSInfo {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AgentName {get; set;}

	[FilterableK()]
	public double OrgId {get; set;}

	[FilterableK()]
	public double MachineGroupId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string MachineGroup {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ComputerName {get; set;}

	[FilterableK()]
	public string IPv6Address {get; set;}

	[FilterableK()]
	public string IPAddress {get; set;}

	[FilterableK()]
	[SortableK()]
	public string OperatingSystem {get; set;}

	[FilterableK()]
	[SortableK()]
	public string OSVersion {get; set;}

	[FilterableK()]
	[SortableK()]
	public string LastLoggedInUser {get; set;}

	[FilterableK()]
	[SortableK()]
	public string LastRebootTime {get; set;}

	[FilterableK()]
	[SortableK()]
	public string LastCheckInTime {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Country {get; set;}

	[FilterableK()]
	[SortableK()]
	public string CurrentUser {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Contact {get; set;}

	[FilterableK()]
	[SortableK()]
	public string TimeZone {get; set;}

	[FilterableK()]
	[SortableK()]
	public int RamMBytes {get; set;}

	[FilterableK()]
	[SortableK()]
	public int CpuCount {get; set;}

	[FilterableK()]
	[SortableK()]
	public int CpuSpeed {get; set;}

	[FilterableK()]
	[SortableK()]
	public string CpuType {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DomainWorkgroup {get; set;}

	[FilterableK()]
	public int AgentFlags {get; set;}

	[FilterableK()]
	public int AgentVersion {get; set;}

	public string ToolTipNotes {get; set;}

	public int ShowToolTip {get; set;}

	public string DefaultGateway {get; set;}

	public string DNSServer1 {get; set;}

	public string DNSServer2 {get; set;}

	public string DHCPServer {get; set;}

	public string PrimaryWINS {get; set;}

	public string SecondaryWINS {get; set;}

	public string ConnectionGatewayIP {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime FirstCheckIn {get; set;}

	public string PrimaryKServer {get; set;}

	public string SecondaryKServer {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime CreationDate {get; set;}

	public bool OneClickAccess {get; set;}

	public object Attributes {get; set;}

}

public class KAgentView : KaseyaObject 
{
	public double ViewDefId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ViewDefName {get; set;}

}

public class KAsset : KaseyaObject 
{
	[FilterableK()]
	public double AssetId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AssetName {get; set;}

	[FilterableK()]
	[SortableK()]
	public double AssetTypeId {get; set;}

	[FilterableK()]
	[SortableK()]
	public double ProbeId {get; set;}

	[FilterableK()]
	public double MachineGroupId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string MachineGroup {get; set;}

	[FilterableK()]
	public double OrgId {get; set;}

	[FilterableK()]
	[SortableK()]
	public bool IsComputerAgent {get; set;}

	[FilterableK()]
	[SortableK()]
	public bool IsMobileAgent {get; set;}

	[FilterableK()]
	[SortableK()]
	public ProbeType IsMonitoring {get; set;}

	[FilterableK()]
	[SortableK()]
	public ProbeType IsPatching {get; set;}

	[FilterableK()]
	[SortableK()]
	public ProbeType IsAuditing {get; set;}

	[FilterableK()]
	[SortableK()]
	public ProbeType IsBackingUp {get; set;}

	[FilterableK()]
	[SortableK()]
	public ProbeType IsSecurity {get; set;}

	[FilterableK()]
	[SortableK()]
	public double TicketCount {get; set;}

	[FilterableK()]
	[SortableK()]
	public double AlarmCount {get; set;}

	[FilterableK()]
	[SortableK()]
	public bool IsSNMPActive {get; set;}

	[FilterableK()]
	[SortableK()]
	public bool IsVProActive {get; set;}

	[FilterableK()]
	[SortableK()]
	public double NetworkInfo {get; set;}

	[FilterableK()]
	public double AgentId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DisplayName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string LastSeenDate {get; set;}

	[FilterableK()]
	[SortableK()]
	public double ProbeAgentGuid {get; set;}

	[FilterableK()]
	[SortableK()]
	public string PrimaryProbe {get; set;}

	[FilterableK()]
	[SortableK()]
	public string PrimaryProbeId {get; set;}

	[FilterableK()]
	[SortableK()]
	public double NMapProbeId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string HostName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string OSName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string OSType {get; set;}

	[FilterableK()]
	[SortableK()]
	public string OSFamily {get; set;}

	[FilterableK()]
	[SortableK()]
	public string OSGeneration {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DeviceManufacturer {get; set;}

	[FilterableK()]
	[SortableK()]
	public object Attributes {get; set;}

}

public class KAssetAdvanced : KaseyaObject 
{
	[FilterableK()]
	public double AssetId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AssetName {get; set;}

	public double AssetTypeId {get; set;}

	[FilterableK()]
	public double MachineGroupId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string MachineGroup {get; set;}

	[FilterableK()]
	public double OrgId {get; set;}

	[FilterableK()]
	public double AgentId {get; set;}

	public double DeviceId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DeviceName {get; set;}

	[FilterableK()]
	[SortableK()]
	public double DeviceType {get; set;}

	public string DeviceTime {get; set;}

	public string ServerTime {get; set;}

	public DeviceFound[] DeviceFound {get; set;}

	public object Attributes {get; set;}

}

public class DeviceFound : KaseyaObject 
{
	public double DeviceId {get; set;}

	public string FoundOn {get; set;}

	public Probe FoundBy {get; set;}

	public DeviceInfo DeviceInfo {get; set;}

	public DeviceMotherBoard DeviceMotherBoard {get; set;}

	public DeviceBiosInfo DeviceBiosInfo {get; set;}

	public DeviceProcessor[] DeviceProcessors {get; set;}

	public DeviceMemory[] DeviceMemories {get; set;}

	public DeviceDrive[] DeviceDrives {get; set;}

	public DeviceIPs[] DeviceIPs {get; set;}

	public DeviceHwPCI[] DeviceHwPCI {get; set;}

}

public class Probe : KaseyaObject 
{
	[FilterableK()]
	public double ProbeId {get; set;}

	[FilterableK()]
	public double ProbeTypeId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProbeName {get; set;}

	public double ProbeAgentId {get; set;}

	public ProbeType ProbeType {get; set;}

	public object Attributes {get; set;}

}

public class DeviceInfo : KaseyaObject 
{
	public string HostName {get; set;}

	public string Manufacturer {get; set;}

	public string Version {get; set;}

	public string SerialNumber {get; set;}

	public double Port {get; set;}

	public string OSName {get; set;}

	public string OSType {get; set;}

	public string OSFamily {get; set;}

	public string OSVendor {get; set;}

	public double OSAccuracy {get; set;}

	public string OSInfo {get; set;}

	public string OSGeneration {get; set;}

}

public class DeviceMotherBoard : KaseyaObject 
{
	public string MotherboardManufacturer {get; set;}

	public string MotherboardProductName {get; set;}

	public string MotherboardVersion {get; set;}

	public string MotherboardSerialNum {get; set;}

	public string MotherboardAssetTag {get; set;}

	public string MotherboardReplaceable {get; set;}

}

public class DeviceBiosInfo : KaseyaObject 
{
	public string BiosVendor {get; set;}

	public string BiosVersion {get; set;}

	public string BiosReleaseDate {get; set;}

	public string BiosSupportedFunctions {get; set;}

}

public class DeviceProcessor : KaseyaObject 
{
	public double ProcessorId {get; set;}

	public string ProcessorManufacturer {get; set;}

	public string ProcessorFamily {get; set;}

	public string ProcessorVersion {get; set;}

	public double ProcessorMaxSpeed {get; set;}

	public double ProcessorCurrentSpeed {get; set;}

	public string ProcessorStatus {get; set;}

	public string ProcessorUpgradeInfo {get; set;}

	public string ProcessorSocketPopulated {get; set;}

	public string ProcessorType {get; set;}

}

public class DeviceMemory : KaseyaObject 
{
	public string MemoryManufacturer {get; set;}

	public string MemorySerialNum {get; set;}

	public double MemorySize {get; set;}

	public double MemorySpeed {get; set;}

	public string MemoryType {get; set;}

}

public class DeviceDrive : KaseyaObject 
{
	public string DriveManufacturer {get; set;}

	public string DriveSocketDesignation {get; set;}

	public string DriveVersion {get; set;}

	public double DriveMaxSpeed {get; set;}

	public double DriveCurrentSpeed {get; set;}

	public string DriveStatus {get; set;}

	public string DriveUpgradeInfo {get; set;}

	public string DriveSocketPopulated {get; set;}

}

public class DeviceIPs : KaseyaObject 
{
	public string IPAddress {get; set;}

	public double IPAddressType {get; set;}

	public string SubnetMask {get; set;}

	public bool DHCPEnabled {get; set;}

	public string IPv6Address {get; set;}

	public string MACAddress {get; set;}

	public string MACManufacturer {get; set;}

}

public class DeviceHwPCI : KaseyaObject 
{
	public double VendorId {get; set;}

	public double ProductId {get; set;}

	public double Revision {get; set;}

	public string DeviceLocation {get; set;}

	public double BaseClass {get; set;}

	public double SubClass {get; set;}

	public double Bus {get; set;}

	public double Slot {get; set;}

	public string SubVendorId {get; set;}

	public string SubSystemId {get; set;}

}

public class ProbeType : KaseyaObject 
{
	[FilterableK()]
	public double ProbeTypeId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProbeTypeName {get; set;}

	public object Attributes {get; set;}

}

public class KAssetType : KaseyaObject 
{
	[FilterableK()]
	public double AssetTypeId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AssetTypeName {get; set;}

	[FilterableK()]
	public double ParentAssetTypeId {get; set;}

	public object Attributes {get; set;}

}

public class K2faSettings : KaseyaObject 
{
	public double AgentID {get; set;}

	public bool AuthEnabled {get; set;}

	public bool UseDefaultUser {get; set;}

	public string UserName {get; set;}

	public string SASName {get; set;}

	public int SiteID {get; set;}

	public string Note {get; set;}

}

public class KRemoteControlNotifyPolicy : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string EmailAddr {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AgentGuid {get; set;}

	[FilterableK()]
	[SortableK()]
	public int AdminGroupId {get; set;}

	[FilterableK()]
	[SortableK()]
	public int RemoteControlNotify {get; set;}

	public string NotifyText {get; set;}

	public string AskText {get; set;}

	[FilterableK()]
	[SortableK()]
	public int TerminateNotify {get; set;}

	[FilterableK()]
	[SortableK()]
	public string TerminateText {get; set;}

	[FilterableK()]
	[SortableK()]
	public int RequireRcNote {get; set;}

	[FilterableK()]
	[SortableK()]
	public int RequiteFTPNote {get; set;}

	[FilterableK()]
	[SortableK()]
	public int RecordSession {get; set;}

}

public class KDocument : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string Name {get; set;}

	[FilterableK()]
	[SortableK()]
	public KScheduledAgentProcedure Size {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime LastUploadTime {get; set;}

	public string ParentPath {get; set;}

	[FilterableK()]
	[SortableK()]
	public bool IsFile {get; set;}

}

public class KFile : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public string Name {get; set;}

	[FilterableK()]
	[SortableK()]
	public KScheduledAgentProcedure Size {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime LastUploadTime {get; set;}

	public string ParentPath {get; set;}

	[FilterableK()]
	[SortableK()]
	public bool IsFile {get; set;}

}

public class KAgentLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Event {get; set;}

}

public class KAgentProcedureLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public DateTime LastExecution {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ProcedureHistory {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Status {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Admin {get; set;}

}

public class KAlarmLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Event {get; set;}

}

public class KConfigChangesLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Event {get; set;}

}

public class KLegacyRemoteControlLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

	[FilterableK()]
	[SortableK()]
	public int Type {get; set;}

	[FilterableK()]
	[SortableK()]
	public int Duration {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Admin {get; set;}

}

public class KMonitorActionLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

	[FilterableK()]
	[SortableK()]
	public string SNMPDevice {get; set;}

	[FilterableK()]
	[SortableK()]
	public int Type {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Message {get; set;}

}

public class KNetworkStatsLog : KaseyaObject 
{
	public int NetworkStatID {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Application {get; set;}

	public int BytesSent {get; set;}

	public int BytesRcvd {get; set;}

}

public class KRemoteControlLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public DateTime StartTime {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime LastActiveTime {get; set;}

	[FilterableK()]
	[SortableK()]
	public int SessionType {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Admin {get; set;}

}

public class KApplicationEventLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public int EventId {get; set;}

	[FilterableK()]
	[SortableK()]
	public KScheduledAgentProcedure User {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Category {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Source {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Type {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

}

public class KDirectoryServiceLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public int EventId {get; set;}

	[FilterableK()]
	[SortableK()]
	public KScheduledAgentProcedure User {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Category {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Source {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Type {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

}

public class KDNSServerEventLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public int EventId {get; set;}

	[FilterableK()]
	[SortableK()]
	public KScheduledAgentProcedure User {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Category {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Source {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Type {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

}

public class KInternetExplorerLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public int EventId {get; set;}

	[FilterableK()]
	[SortableK()]
	public KScheduledAgentProcedure User {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Category {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Source {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Type {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

}

public class KSecurityEventLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public int EventId {get; set;}

	[FilterableK()]
	[SortableK()]
	public KScheduledAgentProcedure User {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Category {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Source {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Type {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

}

public class KSystemEventLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public int EventId {get; set;}

	[FilterableK()]
	[SortableK()]
	public KScheduledAgentProcedure User {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Category {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Source {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Type {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

}

public class KLogMonitoringLog : KaseyaObject 
{
	[FilterableK()]
	[SortableK()]
	public int EventId {get; set;}

	[FilterableK()]
	[SortableK()]
	public KScheduledAgentProcedure User {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Category {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Source {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Type {get; set;}

	[FilterableK()]
	[SortableK()]
	public DateTime Time {get; set;}

}

public class KFunctions : KaseyaObject 
{
	public int TotalRecords {get; set;}

	public int Result {get; set;}

	public int ResponseCode {get; set;}

	public string Status {get; set;}

	public string Error {get; set;}

}

public class KTenant : KaseyaObject 
{
	public double Id {get; set;}

	public string Ref {get; set;}

	public string Type {get; set;}

	public int TimeZoneOffset {get; set;}

	public object Attributes {get; set;}

}

public class KDepartment : KaseyaObject 
{
	[FilterableK()]
	public double DepartmentId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string DepartmentName {get; set;}

	[FilterableK()]
	public double ParentDepartmentId {get; set;}

	[FilterableK()]
	public double ManagerId {get; set;}

	[FilterableK()]
	public double OrgId {get; set;}

	[FilterableK()]
	public string DepartmentRef {get; set;}

	public object Attributes {get; set;}

}

public class KMachineGroup : KaseyaObject 
{
	[FilterableK()]
	public double MachineGroupId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string MachineGroupName {get; set;}

	[FilterableK()]
	public double ParentMachineGroupId {get; set;}

	[FilterableK()]
	[SortableK()]
	public double OrgId {get; set;}

	public object Attributes {get; set;}

}

public class KOrganization : KaseyaObject 
{
	[FilterableK()]
	public double OrgId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string OrgName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string OrgRef {get; set;}

	public string OrgType {get; set;}

	public string DefaultDepartmentName {get; set;}

	public string DefaultMachineGroupName {get; set;}

	[FilterableK()]
	public double ParentOrgId {get; set;}

	public string Website {get; set;}

	[FilterableK()]
	[SortableK()]
	public int NoOfEmployees {get; set;}

	[FilterableK()]
	[SortableK()]
	public double AnnualRevenue {get; set;}

	public ContactInfo ContactInfo {get; set;}

	public CustomFields CustomFields {get; set;}

	public object Attributes {get; set;}

}

public class ContactInfo : KaseyaObject 
{
	public string PreferredContactMethod {get; set;}

	public string PrimaryPhone {get; set;}

	public string PrimaryFax {get; set;}

	public string PrimaryEmail {get; set;}

	public string Country {get; set;}

	public string Street {get; set;}

	public string City {get; set;}

	public string State {get; set;}

	public string ZipCode {get; set;}

	public string PrimaryTextMessagePhone {get; set;}

}

public class CustomFields : KaseyaObject 
{
	public string FieldName {get; set;}

	public string FieldValue {get; set;}

}

public class KUserRole : KaseyaObject 
{
	[FilterableK()]
	public int RoleId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string RoleName {get; set;}

	public double[] RoleTypeIds {get; set;}

	public object Attributes {get; set;}

}

public class KUserRoleType : KaseyaObject 
{
	[FilterableK()]
	public double RoleTypeId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string RoleTypeName {get; set;}

	public string RoleTypeDescription {get; set;}

	public object Attributes {get; set;}

}

public class KScope : KaseyaObject 
{
	[FilterableK()]
	public double ScopeId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string ScopeName {get; set;}

	public object Attributes {get; set;}

}

public class KUser : KaseyaObject 
{
	[FilterableK()]
	public int UserId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AdminName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string AdminPassword {get; set;}

	public int Admintype {get; set;}

	public string DisableUntil {get; set;}

	public string CreationDate {get; set;}

	public double[] AdminScopeIds {get; set;}

	public int[] AdminRoleIds {get; set;}

	[FilterableK()]
	[SortableK()]
	public string FirstName {get; set;}

	[FilterableK()]
	[SortableK()]
	public string LastName {get; set;}

	public double DefaultStaffOrgId {get; set;}

	public double DefaultStaffDepartmentId {get; set;}

	[FilterableK()]
	[SortableK()]
	public string Email {get; set;}

	public object Attributes {get; set;}

}


