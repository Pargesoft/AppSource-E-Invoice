permissionset 80000 "E-Invoice Test"
{
    Assignable = true;
    Permissions = codeunit "E-Invoice Test Codeunit" = X,
                  codeunit "Library - EInvoice EArchive" = X;
}