/// Command Line OpenAPI/Swagger Client Code Generation Tool
// - this program is a part of the Open Source Synopse mORMot framework 2,
// licensed under a MPL/GPL/LGPL three license - see LICENSE.md
program mopenapi;

{
  *****************************************************************************

  Command-Line Tool to Generate client .pas from OpenAPI/Swagger .json specs
  - e.g.   mopenapi swagger.json PetStore
           mopenapi --help
           mopenapi OpenApiAuth.json --options=GenerateSingleApiUnit,DtoNoDescription,ClientNoDescription
  
  *****************************************************************************
}

{$I mormot.defines.inc}

{$ifdef OSWINDOWS}
  {$apptype console}
  {$R ..\..\mormot.win.default.manifest.res}
{$endif OSWINDOWS}

{$R *.res}

uses
  {$I mormot.uses.inc}
  classes,
  sysutils,
  mormot.core.base,
  mormot.core.os,
  mormot.core.text,
  mormot.core.unicode,
  mormot.core.rtti,
  mormot.net.openapi;

type
  // use RTTI for command line options
  TOptions = class(TObjectWithProps)
  protected
    fDestinationFolder: TFileName;
    fOptions: TOpenApiParserOptions;
  published
    property DestinationFolder: TFileName
      read fDestinationFolder write fDestinationFolder;
    property Options: TOpenApiParserOptions
      read fOptions write fOptions;
  end;

var
  o: TOptions;
  oa: TOpenApiParser;
  name: RawUtf8;
  source: TFileName;
  i: PtrInt;
begin
  o := TOptions.Create;
  try
    // validate command line parameters
    with Executable.Command do
    begin
      //RawParams := CsvToRawUtf8DynArray('OpenApiAuth.json'); Parse;
      source := ArgFile(0, 'Source json #filename', {optional=}false);
      name := TrimControlChars(ArgU(1, 'Short description #name of the service'));
      SetObjectFromExecutableCommandLine(o, '', '');
      if o.DestinationFolder <> '' then
        o.DestinationFolder := CheckFileName(o.DestinationFolder, {folder=}true);
      if Option('concise', 'Generate a single API unit') then
        o.Options :=  o.Options + OPENAPI_CONCISE;
      if ConsoleHelpFailed('mORMot ' + SYNOPSE_FRAMEWORK_VERSION +
                                   ' OpenAPI/Swagger Code Generator') then
      begin
        ExitCode := 1;
        exit;
      end;
    end;
    if name = '' then
    begin
      // if no short description name is supplied, extract from specs file name
      name := GetFileNameWithoutExtOrPath(source);
      for i := length(name) downto 1 do
        if name[i] in ['A' .. 'Z'] then
        begin
          delete(name, 1, i - 1); // 'OpenApiTest' -> 'Test'
          break;
        end;
    end;
    try
      // do the actual specs parsing and code generation
      oa := TOpenApiParser.Create(name, o.Options);
      try
        oa.ParseFile(source);
        oa.ExportToDirectory(o.DestinationFolder);
        if not (opoGenerateSingleApiUnit in oa.Options) then
          ConsoleWrite(['Generated ',oa.DtoUnitName, '.pas']);
        ConsoleWrite(['Generated ', oa.ClientUnitName, '.pas for ',
                      oa.ClientClassName]);
      finally
        oa.Free;
      end;
    except
      on E: Exception do
        ConsoleShowFatalException(E);
    end;
  finally
    o.Free;
  end;
end.
