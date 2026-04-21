#Requires -Version 5.1
# Module GS-UI.psm1 - Interface graphique WPF de GameSwap
# Encodage: UTF-8 BOM | Fins de ligne: CRLF

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ===========================================================================
#  ASSISTANT DE CONFIGURATION (premier lancement)
# ===========================================================================

function Show-GSWizard {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptDir,
        [Parameter(Mandatory)]
        [PSCustomObject]$Settings
    )

    $xamlWizard = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="GameSwap - Configuration initiale"
        Height="460" Width="580"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#1E1E2E">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="70"/>
            <RowDefinition Height="56"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="70"/>
        </Grid.RowDefinitions>

        <!-- En-tete -->
        <Border Grid.Row="0" Background="#181825">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="24,0">
                <TextBlock Text="&#9654;" FontSize="26" Foreground="#CBA6F7" VerticalAlignment="Center"/>
                <TextBlock Text="GameSwap" FontSize="26" FontWeight="Bold"
                           Foreground="#CDD6F4" VerticalAlignment="Center" Margin="10,0,0,0"/>
                <TextBlock Text="Configuration" FontSize="14" Foreground="#585B70"
                           VerticalAlignment="Bottom" Margin="12,0,0,6"/>
            </StackPanel>
        </Border>

        <!-- Indicateur d etapes -->
        <Border Grid.Row="1" Background="#181825" BorderBrush="#313244" BorderThickness="0,1,0,1">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="24,0">
                <Border x:Name="indStep1" Background="#CBA6F7" CornerRadius="14" Width="28" Height="28">
                    <TextBlock Text="1" Foreground="#1E1E2E" FontWeight="Bold"
                               HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="13"/>
                </Border>
                <TextBlock x:Name="lblStep1" Text="  Dossier d'installation"
                           Foreground="#CDD6F4" VerticalAlignment="Center" FontSize="13"/>
                <Rectangle Width="50" Height="2" Fill="#45475A" VerticalAlignment="Center" Margin="16,0"/>
                <Border x:Name="indStep2" Background="#45475A" CornerRadius="14" Width="28" Height="28">
                    <TextBlock Text="2" Foreground="#9399B2" FontWeight="Bold"
                               HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="13"/>
                </Border>
                <TextBlock x:Name="lblStep2" Text="  Nom de joueur"
                           Foreground="#585B70" VerticalAlignment="Center" FontSize="13"/>
            </StackPanel>
        </Border>

        <!-- Contenu etape 1 -->
        <Grid x:Name="panelStep1" Grid.Row="2" Margin="24,20,24,0">
            <StackPanel>
                <TextBlock Text="Ou souhaitez-vous installer GameSwap ?"
                           Foreground="#CDD6F4" FontSize="15" FontWeight="SemiBold" Margin="0,0,0,6"/>
                <TextBlock Text="GameSwap cree un sous-dossier 'GameSwap' a l'emplacement choisi. C'est la que seront stockes et partages vos jeux."
                           Foreground="#9399B2" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,20"/>
                <TextBlock Text="Dossier de base :" Foreground="#CDD6F4" FontSize="12" Margin="0,0,0,6"/>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox x:Name="txtBasePath" Grid.Column="0"
                             Background="#313244" Foreground="#CDD6F4"
                             BorderBrush="#45475A" BorderThickness="1"
                             Padding="8,6" FontSize="13" CaretBrush="#CBA6F7"/>
                    <Button x:Name="btnBrowse" Grid.Column="1" Content="Parcourir..."
                            Margin="8,0,0,0" Padding="12,6"
                            Background="#45475A" Foreground="#CDD6F4"
                            BorderThickness="0" Cursor="Hand" FontSize="12"/>
                </Grid>
                <Border Background="#313244" CornerRadius="4" Margin="0,12,0,0" Padding="10,8">
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="Chemin complet : " Foreground="#9399B2" FontSize="12"/>
                        <TextBlock x:Name="txtFullPath" Foreground="#A6E3A1" FontSize="12"
                                   FontWeight="SemiBold" TextWrapping="NoWrap"/>
                    </StackPanel>
                </Border>
                <TextBlock x:Name="txtStep1Error" Foreground="#F38BA8" FontSize="12"
                           Margin="0,10,0,0" Visibility="Collapsed"/>
            </StackPanel>
        </Grid>

        <!-- Contenu etape 2 -->
        <Grid x:Name="panelStep2" Grid.Row="2" Margin="24,20,24,0" Visibility="Collapsed">
            <StackPanel>
                <TextBlock Text="Quel est votre nom de joueur ?"
                           Foreground="#CDD6F4" FontSize="15" FontWeight="SemiBold" Margin="0,0,0,6"/>
                <TextBlock Text="Ce nom sera visible par les autres joueurs sur le reseau. Il ne peut contenir que des lettres et des chiffres (20 caracteres maximum)."
                           Foreground="#9399B2" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,20"/>
                <TextBlock Text="Nom de joueur :" Foreground="#CDD6F4" FontSize="12" Margin="0,0,0,6"/>
                <TextBox x:Name="txtPlayerName"
                         Background="#313244" Foreground="#CDD6F4"
                         BorderBrush="#45475A" BorderThickness="1"
                         Padding="10,8" FontSize="16" MaxLength="20" CaretBrush="#CBA6F7"/>
                <TextBlock x:Name="txtStep2Error" Foreground="#F38BA8" FontSize="12"
                           Margin="0,10,0,0" Visibility="Collapsed"/>
            </StackPanel>
        </Grid>

        <!-- Boutons de navigation -->
        <Border Grid.Row="3" Background="#181825" BorderBrush="#313244" BorderThickness="0,1,0,0">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right"
                        VerticalAlignment="Center" Margin="0,0,24,0">
                <Button x:Name="btnPrev" Content="&lt; Precedent"
                        Visibility="Collapsed" Margin="0,0,8,0" Padding="16,8"
                        Background="#45475A" Foreground="#CDD6F4"
                        BorderThickness="0" Cursor="Hand" FontSize="13"/>
                <Button x:Name="btnNext" Content="Suivant >"
                        Padding="20,8" Background="#CBA6F7" Foreground="#1E1E2E"
                        BorderThickness="0" Cursor="Hand" FontSize="13" FontWeight="SemiBold"/>
            </StackPanel>
        </Border>
    </Grid>
</Window>
'@

    $reader  = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xamlWizard)
    $wizard  = [System.Windows.Markup.XamlReader]::Load($reader)

    $panelStep1   = $wizard.FindName("panelStep1")
    $panelStep2   = $wizard.FindName("panelStep2")
    $indStep2     = $wizard.FindName("indStep2")
    $lblStep2     = $wizard.FindName("lblStep2")
    $txtBasePath  = $wizard.FindName("txtBasePath")
    $txtFullPath  = $wizard.FindName("txtFullPath")
    $txtPlayerName= $wizard.FindName("txtPlayerName")
    $btnBrowse    = $wizard.FindName("btnBrowse")
    $btnPrev      = $wizard.FindName("btnPrev")
    $btnNext      = $wizard.FindName("btnNext")
    $txtStep1Error= $wizard.FindName("txtStep1Error")
    $txtStep2Error= $wizard.FindName("txtStep2Error")

    $script:WizCurrentStep = 1
    $script:WizResult      = $null

    # Valeur initiale: dossier parent du script
    $defaultBase = Split-Path $ScriptDir -Parent
    if (-not $defaultBase) { $defaultBase = $ScriptDir }
    $txtBasePath.Text = $defaultBase
    $txtFullPath.Text = Join-Path $defaultBase "GameSwap"

    # Mise a jour du chemin complet en temps reel
    $txtBasePath.Add_TextChanged({
        $base = $txtBasePath.Text.Trim()
        if ($base) {
            $txtFullPath.Text = Join-Path $base "GameSwap"
        } else {
            $txtFullPath.Text = ""
        }
    })

    # Bouton Parcourir
    $btnBrowse.Add_Click({
        $dlg = [System.Windows.Forms.FolderBrowserDialog]::new()
        $dlg.Description = "Choisissez le dossier de base pour GameSwap"
        $dlg.SelectedPath = $txtBasePath.Text
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtBasePath.Text = $dlg.SelectedPath
        }
    })

    # Fonction passage etape 1 -> 2
    $goToStep2 = {
        $base = $txtBasePath.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($base)) {
            $txtStep1Error.Text       = "Veuillez saisir ou choisir un dossier."
            $txtStep1Error.Visibility = "Visible"
            return
        }
        # Verifier que le chemin est valide (pas de caracteres interdits)
        $invalidChars = [System.IO.Path]::GetInvalidPathChars()
        if ($base.IndexOfAny($invalidChars) -ge 0) {
            $txtStep1Error.Text       = "Le chemin contient des caracteres invalides."
            $txtStep1Error.Visibility = "Visible"
            return
        }
        $txtStep1Error.Visibility = "Collapsed"
        $panelStep1.Visibility    = "Collapsed"
        $panelStep2.Visibility    = "Visible"
        $btnPrev.Visibility       = "Visible"
        $btnNext.Content          = "Terminer"
        # Activer visuellement l etape 2
        $indStep2.Background      = [System.Windows.Media.SolidColorBrush][System.Windows.Media.Color]::FromRgb(0xCB,0xA6,0xF7)
        ($indStep2.Child).Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.Color]::FromRgb(0x1E,0x1E,0x2E)
        $lblStep2.Foreground      = [System.Windows.Media.SolidColorBrush][System.Windows.Media.Color]::FromRgb(0xCD,0xD6,0xF4)
        $script:WizCurrentStep    = 2
        $txtPlayerName.Focus()
    }

    # Fonction finalisation
    $finalize = {
        $name = $txtPlayerName.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($name)) {
            $txtStep2Error.Text       = "Veuillez entrer un nom de joueur."
            $txtStep2Error.Visibility = "Visible"
            return
        }
        if ($name -notmatch '^[a-zA-Z0-9]{1,20}$') {
            $txtStep2Error.Text       = "Uniquement lettres et chiffres, 20 caracteres maximum."
            $txtStep2Error.Visibility = "Visible"
            return
        }
        $txtStep2Error.Visibility = "Collapsed"
        $gsFolder = Join-Path $txtBasePath.Text.Trim() "GameSwap"
        $script:WizResult = [PSCustomObject]@{
            GameSwapFolder = $gsFolder
            PlayerName     = $name
        }
        $wizard.DialogResult = $true
        $wizard.Close()
    }

    $btnNext.Add_Click({
        if ($script:WizCurrentStep -eq 1) { & $goToStep2 }
        else                               { & $finalize }
    })

    $btnPrev.Add_Click({
        if ($script:WizCurrentStep -eq 2) {
            $panelStep2.Visibility = "Collapsed"
            $panelStep1.Visibility = "Visible"
            $btnPrev.Visibility    = "Collapsed"
            $btnNext.Content       = "Suivant >"
            $script:WizCurrentStep = 1
        }
    })

    # Valider avec Entree dans le champ nom
    $txtPlayerName.Add_KeyDown({
        if ($_.Key -eq "Return") { & $finalize }
    })

    [void]$wizard.ShowDialog()
    return $script:WizResult
}

# ===========================================================================
#  FENETRE PRINCIPALE
# ===========================================================================

function Show-GSMainWindow {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Settings,
        [Parameter(Mandatory)]
        [string]$ScriptDir
    )

    $xamlMain = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="GameSwap"
        Height="800" Width="1200"
        MinHeight="580" MinWidth="800"
        WindowStartupLocation="CenterScreen"
        Background="#1E1E2E">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="64"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="32"/>
        </Grid.RowDefinitions>

        <!-- En-tete -->
        <Border Grid.Row="0" Background="#181825">
            <Grid Margin="20,0">
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="&#9654;" FontSize="24" Foreground="#CBA6F7" VerticalAlignment="Center"/>
                    <TextBlock Text="GameSwap" FontSize="22" FontWeight="Bold"
                               Foreground="#CDD6F4" VerticalAlignment="Center" Margin="8,0,0,0"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <Border Background="#313244" CornerRadius="4" Padding="6,3" Margin="0,0,10,0">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="Carte : " Foreground="#9399B2" FontSize="11"
                                       VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <ComboBox x:Name="cmbAdapter" Width="210"
                                      Background="#CDD6F4" Foreground="#1E1E2E"
                                      BorderBrush="#585B70" BorderThickness="1"
                                      Padding="6,2" FontSize="11">
                                <ComboBox.ItemContainerStyle>
                                    <Style TargetType="ComboBoxItem">
                                        <Setter Property="Background" Value="#313244"/>
                                        <Setter Property="Foreground" Value="#CDD6F4"/>
                                        <Setter Property="Padding"    Value="8,5"/>
                                        <Style.Triggers>
                                            <Trigger Property="IsMouseOver" Value="True">
                                                <Setter Property="Background" Value="#45475A"/>
                                            </Trigger>
                                            <Trigger Property="IsSelected" Value="True">
                                                <Setter Property="Background" Value="#585B70"/>
                                                <Setter Property="Foreground" Value="#CDD6F4"/>
                                            </Trigger>
                                        </Style.Triggers>
                                    </Style>
                                </ComboBox.ItemContainerStyle>
                            </ComboBox>
                        </StackPanel>
                    </Border>
                    <Border Background="#313244" CornerRadius="4" Padding="10,4" Margin="0,0,10,0">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="Joueur : " Foreground="#9399B2" FontSize="12"/>
                            <TextBlock x:Name="txtHeaderPlayer" Foreground="#CBA6F7"
                                       FontSize="12" FontWeight="SemiBold"/>
                        </StackPanel>
                    </Border>
                    <Button x:Name="btnQuit" Content="Quitter"
                            Padding="14,4"
                            Background="#F38BA8" Foreground="#1E1E2E"
                            BorderThickness="0" Cursor="Hand"
                            FontSize="12" FontWeight="SemiBold"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Contenu principal : onglets -->
        <TabControl Grid.Row="1" Background="#1E1E2E" BorderThickness="0"
                    Padding="0" Margin="0">
            <TabControl.Resources>
                <Style TargetType="TabItem">
                    <Setter Property="Background" Value="#181825"/>
                    <Setter Property="Foreground" Value="#9399B2"/>
                    <Setter Property="Padding" Value="20,10"/>
                    <Setter Property="FontSize" Value="13"/>
                    <Setter Property="BorderThickness" Value="0"/>
                    <Style.Triggers>
                        <Trigger Property="IsSelected" Value="True">
                            <Setter Property="Background" Value="#1E1E2E"/>
                            <Setter Property="Foreground" Value="#CDD6F4"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>
            </TabControl.Resources>

            <!-- ============================================================
                 ONGLET : MES JEUX
            ============================================================ -->
            <TabItem Header="&#127918;  Mes Jeux">
                <Grid Margin="16,12,16,12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="12"/>
                        <ColumnDefinition Width="230"/>
                    </Grid.ColumnDefinitions>

                    <!-- Tableau des jeux locaux -->
                    <DataGrid x:Name="dgLocalGames" Grid.Row="0" Grid.Column="0"
                              AutoGenerateColumns="False"
                              IsReadOnly="True"
                              SelectionMode="Single"
                              Background="#181825"
                              RowBackground="#1E1E2E"
                              AlternatingRowBackground="#24243A"
                              Foreground="#CDD6F4"
                              BorderBrush="#313244" BorderThickness="1"
                              GridLinesVisibility="Horizontal"
                              HorizontalGridLinesBrush="#313244"
                              HeadersVisibility="Column"
                              ColumnHeaderHeight="36"
                              RowHeight="40"
                              FontSize="13">
                        <DataGrid.ColumnHeaderStyle>
                            <Style TargetType="DataGridColumnHeader">
                                <Setter Property="Background" Value="#313244"/>
                                <Setter Property="Foreground" Value="#9399B2"/>
                                <Setter Property="FontWeight" Value="SemiBold"/>
                                <Setter Property="Padding" Value="12,0"/>
                                <Setter Property="BorderThickness" Value="0,0,1,0"/>
                                <Setter Property="BorderBrush" Value="#45475A"/>
                            </Style>
                        </DataGrid.ColumnHeaderStyle>
                        <DataGrid.CellStyle>
                            <Style TargetType="DataGridCell">
                                <Setter Property="BorderThickness" Value="0"/>
                                <Setter Property="Padding" Value="12,0"/>
                                <Setter Property="Template">
                                    <Setter.Value>
                                        <ControlTemplate TargetType="DataGridCell">
                                            <Border Background="{TemplateBinding Background}"
                                                    Padding="{TemplateBinding Padding}">
                                                <ContentPresenter VerticalAlignment="Center"/>
                                            </Border>
                                        </ControlTemplate>
                                    </Setter.Value>
                                </Setter>
                            </Style>
                        </DataGrid.CellStyle>
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Nom du jeu" Binding="{Binding Nom}" Width="*" MinWidth="180"/>
                            <DataGridTextColumn Header="Taille" Binding="{Binding Taille}" Width="100"/>
                            <DataGridTextColumn Header="Joueurs" Binding="{Binding MaxJoueurs}" Width="70"/>
                            <DataGridTemplateColumn Header="Statut" Width="130">
                                <DataGridTemplateColumn.CellTemplate>
                                    <DataTemplate>
                                        <TextBlock Text="{Binding Statut}"
                                                   Foreground="{Binding StatutCouleur}"
                                                   FontWeight="SemiBold" VerticalAlignment="Center"/>
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                            </DataGridTemplateColumn>
                        </DataGrid.Columns>
                    </DataGrid>

                    <!-- Boutons d action -->
                    <StackPanel Grid.Row="1" Grid.Column="0" Orientation="Horizontal" Margin="0,12,0,0">
                        <Button x:Name="btnRefreshLocal" Content="&#8635;  Actualiser"
                                Padding="16,8" Margin="0,0,8,0"
                                Background="#45475A" Foreground="#CDD6F4"
                                BorderThickness="0" Cursor="Hand" FontSize="13"/>
                        <Button x:Name="btnInstall" Content="&#9660;  Installer"
                                Padding="16,8" Margin="0,0,8,0"
                                Background="#89B4FA" Foreground="#1E1E2E"
                                BorderThickness="0" Cursor="Hand" FontSize="13" FontWeight="SemiBold"
                                IsEnabled="False"/>
                        <Button x:Name="btnPlay" Content="&#9654;  Jouer"
                                Padding="20,8" Margin="0,0,8,0"
                                Background="#A6E3A1" Foreground="#1E1E2E"
                                BorderThickness="0" Cursor="Hand" FontSize="13" FontWeight="SemiBold"
                                IsEnabled="False"/>
                        <Button x:Name="btnServer" Content="&#x25BA;  Serveur"
                                Padding="16,8" Margin="0,0,8,0"
                                Background="#94E2D5" Foreground="#1E1E2E"
                                BorderThickness="0" Cursor="Hand" FontSize="13" FontWeight="SemiBold"
                                IsEnabled="False" Visibility="Collapsed"/>
                        <Button x:Name="btnUninstall" Content="Desinstaller"
                                Padding="16,8" Margin="0,0,8,0"
                                Background="#FAB387" Foreground="#1E1E2E"
                                BorderThickness="0" Cursor="Hand" FontSize="13" FontWeight="SemiBold"
                                IsEnabled="False"/>
                        <Button x:Name="btnDelete" Content="Supprimer"
                                Padding="16,8"
                                Background="#EBA0AC" Foreground="#1E1E2E"
                                BorderThickness="0" Cursor="Hand" FontSize="13" FontWeight="SemiBold"
                                IsEnabled="False"/>
                    </StackPanel>

                    <!-- Message de statut installation -->
                    <TextBlock x:Name="txtLocalStatus" Grid.Row="2" Grid.Column="0"
                               Foreground="#9399B2" FontSize="12" Margin="0,8,0,0"
                               Text="Selectionnez un jeu pour voir les options disponibles."/>

                    <!-- Panneau details jeu local -->
                    <Border Grid.Row="0" Grid.Column="2" Grid.RowSpan="3"
                            Background="#181825" BorderBrush="#313244" BorderThickness="1"
                            CornerRadius="6" Padding="10">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <!-- Vignette (ligne 0, taille naturelle) -->
                            <StackPanel Grid.Row="0">
                                <Image x:Name="imgLocalThumb" MaxWidth="210" MaxHeight="280"
                                       Stretch="Uniform" Margin="0,0,0,6"
                                       HorizontalAlignment="Center" Visibility="Collapsed"/>
                                <Border x:Name="brdLocalNoThumb" Height="140"
                                        Background="#24243A" CornerRadius="4" Margin="0,0,0,6">
                                    <TextBlock Text="Pas de vignette" Foreground="#585B70"
                                               HorizontalAlignment="Center" VerticalAlignment="Center"
                                               FontSize="11"/>
                                </Border>
                            </StackPanel>
                            <!-- Contenu scrollable (ligne 1, remplit le reste) -->
                            <ScrollViewer Grid.Row="1"
                                          VerticalScrollBarVisibility="Auto"
                                          HorizontalScrollBarVisibility="Disabled">
                                <StackPanel>
                                    <!-- Annee de sortie -->
                                    <TextBlock Text="Annee" Foreground="#9399B2" FontSize="11" Margin="0,4,0,2"/>
                                    <TextBlock x:Name="txtLocalReleaseYear" Foreground="#CDD6F4"
                                               FontSize="13" FontWeight="SemiBold" Text="-" Margin="0,0,0,10"/>
                                    <!-- Joueurs max -->
                                    <TextBlock Text="Joueurs max" Foreground="#9399B2" FontSize="11" Margin="0,0,0,2"/>
                                    <TextBlock x:Name="txtLocalMaxPlayers" Foreground="#CDD6F4"
                                               FontSize="13" FontWeight="SemiBold" Text="-" Margin="0,0,0,10"/>
                                    <!-- Trailer -->
                                    <Button x:Name="btnLocalWebsite"
                                            Content="&#9654; Voir le trailer"
                                            FontSize="12" Foreground="#89B4FA"
                                            Background="Transparent" BorderThickness="0"
                                            Cursor="Hand" HorizontalAlignment="Left"
                                            Padding="0" Margin="0,0,0,10" Visibility="Collapsed"/>
                                    <!-- Description -->
                                    <TextBlock Text="Description" Foreground="#9399B2" FontSize="11" Margin="0,0,0,4"/>
                                    <TextBlock x:Name="txtLocalDescription" Text="-"
                                               Foreground="#CDD6F4" FontSize="11"
                                               TextWrapping="Wrap" Margin="0,0,0,10"/>
                                    <!-- Instructions -->
                                    <TextBlock Text="Instructions" Foreground="#9399B2" FontSize="11" Margin="0,0,0,4"/>
                                    <TextBlock x:Name="txtLocalInstructions" Text="-"
                                               Foreground="#CDD6F4" FontSize="11"
                                               TextWrapping="Wrap"/>
                                </StackPanel>
                            </ScrollViewer>
                        </Grid>
                    </Border>
                </Grid>
            </TabItem>

            <!-- ============================================================
                 ONGLET : RESEAU
            ============================================================ -->
            <TabItem Header="&#127760;  Reseau">
                <Grid Margin="16,12,16,12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="260"/>
                        <ColumnDefinition Width="12"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="12"/>
                        <ColumnDefinition Width="230"/>
                    </Grid.ColumnDefinitions>

                    <!-- Barre de scan (toute la largeur) -->
                    <Border Grid.Row="0" Grid.ColumnSpan="5" Background="#181825"
                            CornerRadius="6" Padding="14,10" Margin="0,0,0,12"
                            BorderBrush="#313244" BorderThickness="1">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Button x:Name="btnScan" Grid.Column="0"
                                    Content="  Scanner le reseau"
                                    Padding="16,7"
                                    Background="#CBA6F7" Foreground="#1E1E2E"
                                    BorderThickness="0" Cursor="Hand"
                                    FontSize="13" FontWeight="SemiBold"/>
                            <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="16,0">
                                <ProgressBar x:Name="pbScan" Height="6" IsIndeterminate="False"
                                             Value="0" Minimum="0" Maximum="100"
                                             Background="#313244" Foreground="#CBA6F7"
                                             BorderThickness="0"/>
                                <TextBlock x:Name="txtScanStatus" Foreground="#9399B2" FontSize="11"
                                           Margin="0,4,0,0" Text="Cliquez sur Scanner pour decouvrir les joueurs du reseau."/>
                            </StackPanel>
                            <TextBlock Grid.Column="2" x:Name="txtScanCount"
                                       Foreground="#585B70" FontSize="11"
                                       VerticalAlignment="Center" HorizontalAlignment="Right"/>
                        </Grid>
                    </Border>

                    <!-- Colonne gauche : liste des joueurs -->
                    <TextBlock Grid.Row="1" Grid.Column="0" Text="Joueurs sur le reseau"
                               Foreground="#9399B2" FontSize="12" FontWeight="SemiBold"
                               Margin="0,0,0,6"/>
                    <DataGrid x:Name="dgPlayers" Grid.Row="2" Grid.Column="0"
                              AutoGenerateColumns="False" IsReadOnly="True"
                              SelectionMode="Single"
                              Background="#181825" RowBackground="#1E1E2E"
                              AlternatingRowBackground="#24243A"
                              Foreground="#CDD6F4"
                              BorderBrush="#313244" BorderThickness="1"
                              GridLinesVisibility="Horizontal"
                              HorizontalGridLinesBrush="#313244"
                              HeadersVisibility="Column"
                              ColumnHeaderHeight="32" RowHeight="38" FontSize="12">
                        <DataGrid.ColumnHeaderStyle>
                            <Style TargetType="DataGridColumnHeader">
                                <Setter Property="Background" Value="#313244"/>
                                <Setter Property="Foreground" Value="#9399B2"/>
                                <Setter Property="FontWeight" Value="SemiBold"/>
                                <Setter Property="Padding" Value="10,0"/>
                            </Style>
                        </DataGrid.ColumnHeaderStyle>
                        <DataGrid.CellStyle>
                            <Style TargetType="DataGridCell">
                                <Setter Property="BorderThickness" Value="0"/>
                                <Setter Property="Padding" Value="10,0"/>
                                <Setter Property="Template">
                                    <Setter.Value>
                                        <ControlTemplate TargetType="DataGridCell">
                                            <Border Background="{TemplateBinding Background}"
                                                    Padding="{TemplateBinding Padding}">
                                                <ContentPresenter VerticalAlignment="Center"/>
                                            </Border>
                                        </ControlTemplate>
                                    </Setter.Value>
                                </Setter>
                            </Style>
                        </DataGrid.CellStyle>
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Joueur" Binding="{Binding PlayerName}" Width="*"/>
                            <DataGridTextColumn Header="IP" Binding="{Binding IPAddress}" Width="110"/>
                        </DataGrid.Columns>
                    </DataGrid>

                    <!-- Colonne centre : jeux disponibles -->
                    <TextBlock Grid.Row="1" Grid.Column="2" Text="Jeux disponibles"
                               Foreground="#9399B2" FontSize="12" FontWeight="SemiBold"
                               Margin="0,0,0,6"/>
                    <DataGrid x:Name="dgRemoteGames" Grid.Row="2" Grid.Column="2"
                              AutoGenerateColumns="False" IsReadOnly="True"
                              SelectionMode="Single"
                              Background="#181825" RowBackground="#1E1E2E"
                              AlternatingRowBackground="#24243A"
                              Foreground="#CDD6F4"
                              BorderBrush="#313244" BorderThickness="1"
                              GridLinesVisibility="Horizontal"
                              HorizontalGridLinesBrush="#313244"
                              HeadersVisibility="Column"
                              ColumnHeaderHeight="32" RowHeight="38" FontSize="12">
                        <DataGrid.ColumnHeaderStyle>
                            <Style TargetType="DataGridColumnHeader">
                                <Setter Property="Background" Value="#313244"/>
                                <Setter Property="Foreground" Value="#9399B2"/>
                                <Setter Property="FontWeight" Value="SemiBold"/>
                                <Setter Property="Padding" Value="10,0"/>
                            </Style>
                        </DataGrid.ColumnHeaderStyle>
                        <DataGrid.CellStyle>
                            <Style TargetType="DataGridCell">
                                <Setter Property="BorderThickness" Value="0"/>
                                <Setter Property="Padding" Value="10,0"/>
                                <Setter Property="Template">
                                    <Setter.Value>
                                        <ControlTemplate TargetType="DataGridCell">
                                            <Border Background="{TemplateBinding Background}"
                                                    Padding="{TemplateBinding Padding}">
                                                <ContentPresenter VerticalAlignment="Center"/>
                                            </Border>
                                        </ControlTemplate>
                                    </Setter.Value>
                                </Setter>
                            </Style>
                        </DataGrid.CellStyle>
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Nom du jeu" Binding="{Binding DisplayName}" Width="*" MinWidth="120"/>
                            <DataGridTextColumn Header="Taille" Binding="{Binding SizeText}" Width="80"/>
                            <DataGridTextColumn Header="Joueurs" Binding="{Binding MaxJoueurs}" Width="75"/>
                        </DataGrid.Columns>
                    </DataGrid>

                    <!-- Bouton telecharger + barre de progression -->
                    <StackPanel Grid.Row="3" Grid.Column="2" Margin="0,10,0,0">
                        <ProgressBar x:Name="pbDownload" Height="8"
                                     Minimum="0" Maximum="100" Value="0"
                                     Background="#313244" Foreground="#A6E3A1"
                                     BorderThickness="0" Visibility="Collapsed"/>
                        <TextBlock x:Name="txtDownloadStatus" Foreground="#9399B2" FontSize="11"
                                   Margin="0,4,0,0" Visibility="Collapsed"/>
                    </StackPanel>
                    <StackPanel Grid.Row="4" Grid.Column="2" Orientation="Horizontal" Margin="0,8,0,0">
                        <Button x:Name="btnDownload"
                                Content="&#8659;  Telecharger ce jeu"
                                Padding="16,8"
                                Background="#74C7EC" Foreground="#1E1E2E"
                                BorderThickness="0" Cursor="Hand"
                                FontSize="13" FontWeight="SemiBold"
                                IsEnabled="False"/>
                        <Button x:Name="btnCancelDownload"
                                Content="&#9632;  Stopper"
                                Padding="12,8" Margin="8,0,0,0"
                                Background="#F9E2AF" Foreground="#1E1E2E"
                                BorderThickness="0" Cursor="Hand"
                                FontSize="12" FontWeight="SemiBold"
                                Visibility="Collapsed"/>
                        <Button x:Name="btnCancelQueue"
                                Content="Annuler l'attente"
                                Padding="12,8" Margin="8,0,0,0"
                                Background="#F5C2E7" Foreground="#1E1E2E"
                                BorderThickness="0" Cursor="Hand"
                                FontSize="12" FontWeight="SemiBold"
                                Visibility="Collapsed"/>
                    </StackPanel>
                    <TextBlock x:Name="txtNetStatus" Grid.Row="5" Grid.Column="0"
                               Grid.ColumnSpan="5"
                               Foreground="#9399B2" FontSize="12" Margin="0,8,0,0"/>

                    <!-- Panneau details jeu distant (colonne droite) -->
                    <Border x:Name="brdRemoteDetails" Grid.Row="0" Grid.Column="4"
                            Grid.RowSpan="5"
                            Background="#181825" BorderBrush="#313244" BorderThickness="1"
                            CornerRadius="6" Padding="10">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <!-- Vignette (ligne 0, taille naturelle) -->
                            <StackPanel Grid.Row="0">
                                <Image x:Name="imgRemoteThumb"
                                       MaxWidth="210" MaxHeight="280"
                                       Stretch="Uniform" Margin="0,0,0,6"
                                       HorizontalAlignment="Center" Visibility="Collapsed"/>
                                <Border x:Name="brdRemoteNoThumb" Height="140"
                                        Background="#24243A" CornerRadius="4" Margin="0,0,0,6">
                                    <TextBlock Text="Pas de vignette" Foreground="#585B70"
                                               HorizontalAlignment="Center" VerticalAlignment="Center"
                                               FontSize="11"/>
                                </Border>
                            </StackPanel>
                            <!-- Contenu scrollable (ligne 1, remplit le reste) -->
                            <ScrollViewer Grid.Row="1"
                                          VerticalScrollBarVisibility="Auto"
                                          HorizontalScrollBarVisibility="Disabled">
                                <StackPanel>
                                    <!-- Annee de sortie -->
                                    <TextBlock Text="Annee" Foreground="#9399B2" FontSize="11" Margin="0,4,0,2"/>
                                    <TextBlock x:Name="txtRemoteReleaseYear" Foreground="#CDD6F4"
                                               FontSize="13" FontWeight="SemiBold" Text="-" Margin="0,0,0,10"/>
                                    <!-- Joueurs max -->
                                    <TextBlock Text="Joueurs max" Foreground="#9399B2" FontSize="11" Margin="0,0,0,2"/>
                                    <TextBlock x:Name="txtRemoteMaxPlayers" Foreground="#CDD6F4"
                                               FontSize="13" FontWeight="SemiBold" Text="-" Margin="0,0,0,10"/>
                                    <!-- Trailer -->
                                    <Button x:Name="btnRemoteWebsite"
                                            Content="&#9654; Voir le trailer"
                                            FontSize="12" Foreground="#89B4FA"
                                            Background="Transparent" BorderThickness="0"
                                            Cursor="Hand" HorizontalAlignment="Left"
                                            Padding="0" Margin="0,0,0,10"
                                            Visibility="Collapsed"/>
                                    <!-- Description -->
                                    <TextBlock Text="Description" Foreground="#9399B2" FontSize="11" Margin="0,0,0,4"/>
                                    <TextBlock x:Name="txtRemoteDesc" Foreground="#CDD6F4"
                                               FontSize="11" TextWrapping="Wrap"/>
                                </StackPanel>
                            </ScrollViewer>
                        </Grid>
                    </Border>
                </Grid>
            </TabItem>
            <!-- ============================================================
                 ONGLET : PARAMETRAGE
            ============================================================ -->
            <TabItem Header="&#9881;  Parametrage">
                <Grid Margin="16,12,16,12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="24"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <!-- Colonne gauche : Nom du joueur + Dossier jeux -->
                    <StackPanel Grid.Row="0" Grid.Column="0" Margin="0,0,0,16">
                        <TextBlock Text="Nom du joueur" Foreground="#9399B2" FontSize="12" FontWeight="SemiBold" Margin="0,0,0,6"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="8"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBox x:Name="txtSettingsPlayerName" Grid.Column="0"
                                     Background="#313244" Foreground="#CDD6F4"
                                     BorderBrush="#45475A" BorderThickness="1"
                                     Padding="8,6" FontSize="13"/>
                            <Button x:Name="btnApplyPlayerName" Grid.Column="2"
                                    Content="Appliquer"
                                    Padding="12,6" Background="#B4BEFE" Foreground="#1E1E2E"
                                    BorderThickness="0" Cursor="Hand" FontSize="12" FontWeight="SemiBold"/>
                        </Grid>
                    </StackPanel>

                    <StackPanel Grid.Row="1" Grid.Column="0" Margin="0,0,0,16">
                        <TextBlock Text="Dossier des jeux" Foreground="#9399B2" FontSize="12" FontWeight="SemiBold" Margin="0,0,0,6"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="8"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="8"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBox x:Name="txtSettingsFolder" Grid.Column="0"
                                     Background="#313244" Foreground="#CDD6F4"
                                     BorderBrush="#45475A" BorderThickness="1"
                                     Padding="8,6" FontSize="12"/>
                            <Button x:Name="btnBrowseFolder" Grid.Column="2"
                                    Content="..."
                                    Padding="10,6" Background="#585B70" Foreground="#CDD6F4"
                                    BorderThickness="0" Cursor="Hand" FontSize="12"/>
                            <Button x:Name="btnApplyFolder" Grid.Column="4"
                                    Content="Appliquer"
                                    Padding="12,6" Background="#89DCEB" Foreground="#1E1E2E"
                                    BorderThickness="0" Cursor="Hand" FontSize="12" FontWeight="SemiBold"/>
                        </Grid>
                    </StackPanel>

                    <!-- Colonne droite : Slots de telechargement -->
                    <StackPanel Grid.Row="0" Grid.Column="2" Grid.RowSpan="2">
                        <TextBlock Text="Telechargements simultanes" Foreground="#9399B2"
                                   FontSize="12" FontWeight="SemiBold" Margin="0,0,0,6"/>
                        <Grid Margin="0,0,0,16">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="8"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="8"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="8"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Button x:Name="btnSlotsDown" Grid.Column="0" Content="-"
                                    Width="30" Height="30"
                                    Background="#6C7086" Foreground="#CDD6F4"
                                    BorderThickness="0" Cursor="Hand" FontSize="16" FontWeight="Bold"/>
                            <TextBlock x:Name="txtSlotsCount" Grid.Column="2"
                                       Foreground="#CDD6F4" FontSize="20" FontWeight="Bold"
                                       VerticalAlignment="Center" HorizontalAlignment="Center"
                                       MinWidth="24" TextAlignment="Center" Text="3"/>
                            <Button x:Name="btnSlotsUp" Grid.Column="4" Content="+"
                                    Width="30" Height="30"
                                    Background="#7F849C" Foreground="#CDD6F4"
                                    BorderThickness="0" Cursor="Hand" FontSize="16" FontWeight="Bold"/>
                            <Button x:Name="btnApplySlots" Grid.Column="6" Content="Appliquer"
                                    Padding="12,6"
                                    Background="#F2CDCD" Foreground="#1E1E2E"
                                    BorderThickness="0" Cursor="Hand" FontSize="12" FontWeight="SemiBold"/>
                        </Grid>
                        <TextBlock Text="Telechargements actifs" Foreground="#9399B2"
                                   FontSize="12" FontWeight="SemiBold" Margin="0,0,0,6"/>
                        <TextBlock x:Name="txtSlotsInfo" Foreground="#585B70" FontSize="11"
                                   Margin="0,0,0,8" Text="Aucun telechargement en cours."/>
                        <DataGrid x:Name="dgSlots"
                                  AutoGenerateColumns="False" IsReadOnly="True"
                                  SelectionMode="Single"
                                  Background="#181825" RowBackground="#1E1E2E"
                                  AlternatingRowBackground="#24243A"
                                  Foreground="#CDD6F4"
                                  BorderBrush="#313244" BorderThickness="1"
                                  GridLinesVisibility="Horizontal"
                                  HorizontalGridLinesBrush="#313244"
                                  HeadersVisibility="Column"
                                  ColumnHeaderHeight="32" RowHeight="36" FontSize="12"
                                  MaxHeight="180">
                            <DataGrid.ColumnHeaderStyle>
                                <Style TargetType="DataGridColumnHeader">
                                    <Setter Property="Background" Value="#313244"/>
                                    <Setter Property="Foreground" Value="#9399B2"/>
                                    <Setter Property="FontWeight" Value="SemiBold"/>
                                    <Setter Property="Padding" Value="10,0"/>
                                </Style>
                            </DataGrid.ColumnHeaderStyle>
                            <DataGrid.Columns>
                                <DataGridTextColumn Header="Joueur" Binding="{Binding PlayerName}" Width="*"/>
                                <DataGridTextColumn Header="Jeu" Binding="{Binding GameName}" Width="*"/>
                                <DataGridTextColumn Header="Debut" Binding="{Binding StartedAt}" Width="130"/>
                            </DataGrid.Columns>
                        </DataGrid>
                        <StackPanel Orientation="Horizontal" Margin="0,8,0,0">
                            <Button x:Name="btnRefreshSlots" Content="&#8635; Actualiser"
                                    Padding="12,6" Margin="0,0,8,0"
                                    Background="#A6ADC8" Foreground="#1E1E2E"
                                    BorderThickness="0" Cursor="Hand" FontSize="12"/>
                            <Button x:Name="btnClearSlot" Content="Liberer"
                                    Padding="12,6"
                                    Background="#F5E0DC" Foreground="#1E1E2E"
                                    BorderThickness="0" Cursor="Hand" FontSize="12" FontWeight="SemiBold"
                                    IsEnabled="False"/>
                        </StackPanel>
                    </StackPanel>

                    <!-- Redistribuables systeme -->
                    <StackPanel Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="3" Margin="0,8,0,0">
                        <TextBlock Text="Redistribuables systeme" Foreground="#9399B2"
                                   FontSize="12" FontWeight="SemiBold" Margin="0,0,0,8"/>
                        <StackPanel Orientation="Horizontal">
                            <Button x:Name="btnInstallVCRedist"
                                    Content="&#9660;  Visual C++ (toutes versions)"
                                    Padding="14,8" Margin="0,0,12,0"
                                    Background="#E5C890" Foreground="#1E1E2E"
                                    BorderThickness="0" Cursor="Hand" FontSize="12" FontWeight="SemiBold"/>
                            <Button x:Name="btnInstallDirectX"
                                    Content="&#9660;  DirectX June 2010"
                                    Padding="14,8"
                                    Background="#81C8BE" Foreground="#1E1E2E"
                                    BorderThickness="0" Cursor="Hand" FontSize="12" FontWeight="SemiBold"/>
                        </StackPanel>
                    </StackPanel>

                    <TextBlock x:Name="txtSettingsStatus" Grid.Row="3" Grid.Column="0"
                               Grid.ColumnSpan="3"
                               Foreground="#9399B2" FontSize="12" Margin="0,16,0,0"/>
                </Grid>
            </TabItem>

        </TabControl>

        <!-- Barre de statut -->
        <Border Grid.Row="2" Background="#181825" BorderBrush="#313244" BorderThickness="0,1,0,0">
            <TextBlock x:Name="txtStatusBar"
                       Foreground="#585B70" FontSize="11"
                       VerticalAlignment="Center" Margin="16,0"
                       Text="GameSwap pret."/>
        </Border>
    </Grid>
</Window>
'@

    $reader  = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xamlMain)
    $window  = [System.Windows.Markup.XamlReader]::Load($reader)

    # Recuperer les elements
    $txtHeaderPlayer  = $window.FindName("txtHeaderPlayer")
    $dgLocalGames     = $window.FindName("dgLocalGames")
    $btnRefreshLocal  = $window.FindName("btnRefreshLocal")
    $btnInstall       = $window.FindName("btnInstall")
    $btnPlay          = $window.FindName("btnPlay")
    $btnServer        = $window.FindName("btnServer")
    $btnUninstall     = $window.FindName("btnUninstall")
    $btnDelete        = $window.FindName("btnDelete")
    $txtLocalStatus   = $window.FindName("txtLocalStatus")
    $btnScan          = $window.FindName("btnScan")
    $pbScan           = $window.FindName("pbScan")
    $txtScanStatus    = $window.FindName("txtScanStatus")
    $txtScanCount     = $window.FindName("txtScanCount")
    $cmbAdapter       = $window.FindName("cmbAdapter")
    $btnQuit          = $window.FindName("btnQuit")
    $dgPlayers        = $window.FindName("dgPlayers")
    $dgRemoteGames    = $window.FindName("dgRemoteGames")
    $btnDownload        = $window.FindName("btnDownload")
    $btnCancelDownload  = $window.FindName("btnCancelDownload")
    $btnCancelQueue     = $window.FindName("btnCancelQueue")
    $pbDownload       = $window.FindName("pbDownload")
    $txtDownloadStatus= $window.FindName("txtDownloadStatus")
    $txtNetStatus     = $window.FindName("txtNetStatus")
    $txtStatusBar     = $window.FindName("txtStatusBar")
    # Details jeu local
    $imgLocalThumb    = $window.FindName("imgLocalThumb")
    $brdLocalNoThumb  = $window.FindName("brdLocalNoThumb")
    $txtLocalMaxPlayers   = $window.FindName("txtLocalMaxPlayers")
    $btnLocalWebsite      = $window.FindName("btnLocalWebsite")
    $txtLocalDescription  = $window.FindName("txtLocalDescription")
    $txtLocalInstructions = $window.FindName("txtLocalInstructions")
    $txtLocalReleaseYear  = $window.FindName("txtLocalReleaseYear")
    # Details jeu distant
    $imgRemoteThumb   = $window.FindName("imgRemoteThumb")
    $brdRemoteNoThumb = $window.FindName("brdRemoteNoThumb")
    $txtRemoteMaxPlayers = $window.FindName("txtRemoteMaxPlayers")
    $btnRemoteWebsite = $window.FindName("btnRemoteWebsite")
    $txtRemoteDesc    = $window.FindName("txtRemoteDesc")
    $txtRemoteReleaseYear = $window.FindName("txtRemoteReleaseYear")

    # Dossier Jeux local (script: pour pouvoir etre mis a jour depuis btnApplyFolder)
    $script:GamesFolder = Join-Path $Settings.GameSwapFolder "Jeux"

    # -----------------------------------------------------------------------
    # Adaptateurs reseau : remplissage du ComboBox et selection initiale
    # -----------------------------------------------------------------------
    $script:AllAdapters = @(Get-AllNetworkAdapters)
    foreach ($a in $script:AllAdapters) {
        [void]$cmbAdapter.Items.Add($a.DisplayName)
    }

    # Pre-selectionner l'adaptateur sauvegarde, sinon le premier
    $savedIndex = 0
    if ($Settings.SelectedAdapterIP) {
        $found = $script:AllAdapters | Where-Object { $_.IPAddress -eq $Settings.SelectedAdapterIP }
        if ($found) {
            $savedIndex = [array]::IndexOf($script:AllAdapters, $found)
        }
    }
    $cmbAdapter.SelectedIndex = $savedIndex
    # Forcer le texte lisible dans la boite fermee (WPF ignore Foreground XAML sur l'item selectionne)
    $cmbAdapter.Foreground = [System.Windows.Media.SolidColorBrush]::new(
        [System.Windows.Media.Color]::FromRgb(0x1E, 0x1E, 0x2E))
    $cmbAdapter.Background = [System.Windows.Media.SolidColorBrush]::new(
        [System.Windows.Media.Color]::FromRgb(0xCD, 0xD6, 0xF4))

    # Fonction interne : retourne l'adaptateur actuellement selectionne
    $getSelectedAdapter = {
        $idx = $cmbAdapter.SelectedIndex
        if ($idx -ge 0 -and $idx -lt $script:AllAdapters.Count) {
            return $script:AllAdapters[$idx]
        }
        return $null
    }

    $ipInfo  = & $getSelectedAdapter
    $localIP = if ($ipInfo) { $ipInfo.IPAddress } else { "Inconnu" }

    $txtHeaderPlayer.Text = $Settings.PlayerName

    # Changement d'adaptateur a la volee
    $cmbAdapter.Add_SelectionChanged({
        $selected = & $getSelectedAdapter
        if (-not $selected) { return }
        $txtStatusBar.Text    = "Carte reseau : $($selected.InterfaceAlias) - $($selected.IPAddress)"
        Write-GSLog "Adaptateur selectionne: $($selected.DisplayName)" -Level "INFO"
        # Sauvegarder le choix
        $Settings.SelectedAdapterIP = $selected.IPAddress
        Save-GSSettings -Settings $Settings
        # Reinitialiser les resultats du scan precedent (devenu invalide)
        $dgPlayers.ItemsSource     = $null
        $dgRemoteGames.ItemsSource = $null
        $txtScanStatus.Text        = "Carte reseau changee. Relancez le scan."
        $txtScanCount.Text         = ""
    })

    # Bouton Quitter (accessible depuis n'importe quel onglet)
    $btnQuit.Add_Click({
        $gameRunning   = $script:GameProcess   -and -not $script:GameProcess.HasExited
        $serverRunning = $script:ServerProcess -and -not $script:ServerProcess.HasExited

        if ($gameRunning -or $serverRunning) {
            $what = if ($gameRunning -and $serverRunning) { "un jeu et un serveur sont" } `
                    elseif ($gameRunning)                 { "un jeu est" } `
                    else                                  { "un serveur est" }
            $confirm = [System.Windows.MessageBox]::Show(
                "Attention, $what encore en cours d'execution.`nFermer quand meme et arreter le(s) processus ?",
                "Processus en cours", "YesNo", "Warning")
            if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

            if ($gameRunning) {
                try { $script:GameProcess.Kill() } catch {}
                if ($script:GameTimer) { $script:GameTimer.Stop(); $script:GameTimer = $null }
                if ($script:GameVhdxPath) { Dismount-GSVhdxByPath -VhdxPath $script:GameVhdxPath }
                $script:GameProcess = $null; $script:GameVhdxPath = $null
            }
            if ($serverRunning) {
                try { $script:ServerProcess.Kill() } catch {}
                if ($script:ServerVhdxPath) { Dismount-GSVhdxByPath -VhdxPath $script:ServerVhdxPath }
                $script:ServerProcess = $null; $script:ServerVhdxPath = $null; $script:ServerRunning = $false
            }
        }
        $window.Close()
    })

    # -----------------------------------------------------------------------
    # Fonction de chargement des jeux locaux
    # -----------------------------------------------------------------------
    $script:LocalGames = @()

    $loadLocalGames = {
        $script:LocalGames = @(Get-LocalGames -GamesFolder $script:GamesFolder)
        $rows = $script:LocalGames | ForEach-Object {
            $g = $_
            $mp  = if ($g.ExtraInfo -and $g.ExtraInfo.MaxPlayers) { $g.ExtraInfo.MaxPlayers } else { "-" }
            $nom = if ($g.ExtraInfo -and -not [string]::IsNullOrWhiteSpace($g.ExtraInfo.DisplayName)) { $g.ExtraInfo.DisplayName } else { $g.GameName }
            [PSCustomObject]@{
                Nom          = $nom
                Taille       = $g.SizeText
                MaxJoueurs   = $mp
                Statut       = if ($g.IsInstalled) { "Installe" } else { "Non installe" }
                StatutCouleur= if ($g.IsInstalled) { "#A6E3A1" } else { "#F9E2AF" }
            }
        }
        $dgLocalGames.ItemsSource = [object[]]@($rows)
        $btnInstall.IsEnabled   = $false
        $btnPlay.IsEnabled      = $false
        $btnServer.IsEnabled    = $false
        $btnServer.Visibility   = "Collapsed"
        $btnUninstall.IsEnabled = $false
        $btnDelete.IsEnabled    = $false
        $count = $script:LocalGames.Count
        $txtLocalStatus.Text = if ($count -eq 0) { "Aucun jeu trouve. Telechargez des jeux depuis l'onglet Reseau." } `
                               else { "$count jeu(x) present(s) dans votre bibliotheque." }
        $txtStatusBar.Text = "Bibliotheque actualisee - $count jeu(x)."
    }

    & $loadLocalGames

    # -----------------------------------------------------------------------
    # Selection dans la liste des jeux locaux
    # -----------------------------------------------------------------------
    $dgLocalGames.Add_SelectionChanged({
        $idx = $dgLocalGames.SelectedIndex
        if ($idx -lt 0 -or $idx -ge $script:LocalGames.Count) {
            $btnInstall.IsEnabled    = $false
            $btnPlay.IsEnabled       = $false
            $btnServer.IsEnabled     = $false
            $btnServer.Visibility    = "Collapsed"
            $btnUninstall.IsEnabled  = $false
            $btnDelete.IsEnabled     = $false
            $txtLocalStatus.Text     = "Selectionnez un jeu pour voir les options disponibles."
            return
        }
        $game = $script:LocalGames[$idx]
        $hasServer = $game.IsInstalled -and -not [string]::IsNullOrWhiteSpace($game.GameInfo.ServerCommand)
        $btnInstall.IsEnabled    = (-not $game.IsInstalled)
        $btnPlay.IsEnabled       = $game.IsInstalled
        $btnServer.IsEnabled     = $hasServer
        $btnServer.Visibility    = if ($hasServer) { "Visible" } else { "Collapsed" }
        $btnUninstall.IsEnabled  = $game.IsInstalled
        $btnDelete.IsEnabled     = $true
        $statusMsg = if ($game.IsInstalled) {
            "Installe le $($game.GameInfo.InstalledDate) - Commande : $($game.GameInfo.LaunchCommand)"
        } else {
            "Non installe. Cliquez sur 'Installer' pour lancer l'installation."
        }
        $txtLocalStatus.Text = $statusMsg

        # Panneau details
        $extra = $game.ExtraInfo
        $txtLocalReleaseYear.Text = if ($extra -and -not [string]::IsNullOrWhiteSpace($extra.ReleaseYear)) { $extra.ReleaseYear } else { "-" }
        if ($extra -and $extra.MaxPlayers) {
            $txtLocalMaxPlayers.Text = $extra.MaxPlayers
        } else {
            $txtLocalMaxPlayers.Text = "-"
        }

        $trailer = if ($extra) { $extra.Trailer } else { "" }
        if (-not [string]::IsNullOrWhiteSpace($trailer)) {
            $script:LocalTrailerUrl     = $trailer
            $btnLocalWebsite.Visibility = "Visible"
        } else {
            $script:LocalTrailerUrl     = ""
            $btnLocalWebsite.Visibility = "Collapsed"
        }

        $txtLocalDescription.Text = if ($extra -and -not [string]::IsNullOrWhiteSpace($extra.Description)) {
            $extra.Description
        } else { "-" }

        $txtLocalInstructions.Text = if ($extra -and -not [string]::IsNullOrWhiteSpace($extra.Instructions)) {
            $extra.Instructions
        } else { "-" }

        if ($game.ThumbPath) {
            try {
                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                $bmp.BeginInit()
                $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $bmp.UriSource   = [Uri]::new($game.ThumbPath, [System.UriKind]::Absolute)
                $bmp.EndInit()
                $bmp.Freeze()
                $imgLocalThumb.Source     = $bmp
                $imgLocalThumb.Visibility = "Visible"
                $brdLocalNoThumb.Visibility = "Collapsed"
            } catch {
                $imgLocalThumb.Visibility   = "Collapsed"
                $brdLocalNoThumb.Visibility = "Visible"
            }
        } else {
            $imgLocalThumb.Source       = $null
            $imgLocalThumb.Visibility   = "Collapsed"
            $brdLocalNoThumb.Visibility = "Visible"
        }
    })

    $btnLocalWebsite.Add_Click({
        if ($script:LocalTrailerUrl) { Start-Process $script:LocalTrailerUrl }
    })

    $btnRemoteWebsite.Add_Click({
        if ($script:RemoteTrailerUrl) { Start-Process $script:RemoteTrailerUrl }
    })

    # -----------------------------------------------------------------------
    # Bouton Actualiser
    # -----------------------------------------------------------------------
    $btnRefreshLocal.Add_Click({
        $btnRefreshLocal.IsEnabled = $false
        $txtLocalStatus.Foreground = [System.Windows.Media.SolidColorBrush]::new(
            [System.Windows.Media.Color]::FromRgb(0xCB,0xA6,0xF7))
        $txtLocalStatus.Text = "Actualisation en cours..."

        $script:BlinkCount = 0
        $script:BlinkTimer = [System.Windows.Threading.DispatcherTimer]::new()
        $script:BlinkTimer.Interval = [TimeSpan]::FromMilliseconds(300)
        $script:BlinkTimer.Add_Tick({
            $script:BlinkCount++
            $txtLocalStatus.Foreground = if (($script:BlinkCount % 2) -eq 0) {
                [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0xCB,0xA6,0xF7))
            } else {
                [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x45,0x47,0x5A))
            }
            if ($script:BlinkCount -ge 6) {
                $script:BlinkTimer.Stop()
                & $loadLocalGames
                $txtLocalStatus.Foreground = [System.Windows.Media.SolidColorBrush]::new(
                    [System.Windows.Media.Color]::FromRgb(0x93,0x99,0xB2))
                $btnRefreshLocal.IsEnabled = $true
            }
        })
        $script:BlinkTimer.Start()
    })

    # -----------------------------------------------------------------------
    # Bouton Installer
    # -----------------------------------------------------------------------
    $btnInstall.Add_Click({
        $idx = $dgLocalGames.SelectedIndex
        if ($idx -lt 0) { return }
        $game = $script:LocalGames[$idx]

        $confirm = [System.Windows.MessageBox]::Show(
            "Installer '$($game.GameName)' ?`nLe VHDX sera monte et le fichier install.ps1 sera execute.",
            "Installation", "YesNo", "Question")
        if ($confirm -ne "Yes") { return }

        $btnInstall.IsEnabled = $false
        $txtLocalStatus.Text  = "Installation en cours, veuillez patienter..."
        $txtStatusBar.Text    = "Installation de '$($game.GameName)'..."

        try {
            Install-GSGame -VhdxPath $game.VhdxPath -GameFolder $game.FolderPath -GameName $game.GameName
            [System.Windows.MessageBox]::Show("Installation de '$($game.GameName)' terminee avec succes !", "Succes", "OK", "Information")
            & $loadLocalGames
        } catch {
            [System.Windows.MessageBox]::Show("Erreur lors de l'installation :`n$_", "Erreur", "OK", "Error")
            $txtLocalStatus.Text = "Erreur d'installation. Consultez les logs pour plus de details."
            $btnInstall.IsEnabled = $true
        }
        $txtStatusBar.Text = "Pret."
    })

    # -----------------------------------------------------------------------
    # Bouton Jouer
    # -----------------------------------------------------------------------
    $btnPlay.Add_Click({
        $idx = $dgLocalGames.SelectedIndex
        if ($idx -lt 0) { return }
        $game = $script:LocalGames[$idx]

        try {
            $result = Start-GSGame -Game $game
            $script:GameProcess  = $result.Process
            $script:GameVhdxPath = $result.VhdxPath
            $txtStatusBar.Text = "Lancement de '$($game.GameName)'..."
            Write-GSLog "Jeu lance: $($game.GameName)" -Level "INFO"

            # Surveiller la fin du jeu pour demonter le VHDX
            if ($script:GameTimer) {
                $script:GameTimer.Stop()
            }
            $script:GameTimer = New-Object System.Windows.Threading.DispatcherTimer
            $script:GameTimer.Interval = [TimeSpan]::FromSeconds(3)
            $script:GameTimer.Add_Tick({
                if ($script:GameProcess -and $script:GameProcess.HasExited) {
                    $script:GameTimer.Stop()
                    $script:GameTimer = $null
                    if ($script:GameVhdxPath -and -not $script:ServerRunning) {
                        Dismount-GSVhdxByPath -VhdxPath $script:GameVhdxPath
                        Write-GSLog "VHDX demonte apres fermeture du jeu" -Level "INFO"
                        $script:GameVhdxPath = $null
                    } elseif ($script:ServerRunning) {
                        Write-GSLog "VHDX conserve monte (serveur en cours)" -Level "INFO"
                        $script:GameVhdxPath = $null
                    }
                    $script:GameProcess = $null
                    $txtStatusBar.Text = "Jeu ferme."
                }
            })
            $script:GameTimer.Start()
        } catch {
            [System.Windows.MessageBox]::Show("Impossible de lancer le jeu :`n$_", "Erreur", "OK", "Error")
        }
    })

    # -----------------------------------------------------------------------
    # Bouton Serveur (toggle Start / Stop)
    # -----------------------------------------------------------------------
    $script:ServerRunning = $false

    $btnServer.Add_Click({
        # --- STOP ---
        if ($script:ServerRunning) {
            if ($script:ServerProcess -and -not $script:ServerProcess.HasExited) {
                try { $script:ServerProcess.Kill() } catch {}
            }
            if ($script:ServerVhdxPath) {
                Dismount-GSVhdxByPath -VhdxPath $script:ServerVhdxPath
                Write-GSLog "VHDX demonte (arret serveur manuel)" -Level "INFO"
                $script:ServerVhdxPath = $null
            }
            $script:ServerProcess  = $null
            $script:ServerRunning  = $false
            $btnServer.Content     = "$([char]0x25BA)  Serveur"
            $btnServer.Background  = "#FAB387"
            $txtStatusBar.Text     = "Serveur arrete."
            return
        }

        # --- START ---
        $idx = $dgLocalGames.SelectedIndex
        if ($idx -lt 0) { return }
        $game = $script:LocalGames[$idx]

        try {
            $result = Start-GSServer -Game $game
            $script:ServerProcess  = $result.Process
            $script:ServerVhdxPath = $result.VhdxPath
            $script:ServerRunning  = $true
            $btnServer.Content     = "$([char]0x25A0)  Arreter serveur"
            $btnServer.Background  = "#F38BA8"
            $txtStatusBar.Text     = "Serveur '$($game.GameName)' demarre..."
            Write-GSLog "Serveur lance: $($game.GameName)" -Level "INFO"
        } catch {
            [System.Windows.MessageBox]::Show("Impossible de lancer le serveur :`n$_", "Erreur", "OK", "Error")
        }
    })

    # -----------------------------------------------------------------------
    # Bouton Desinstaller (supprime uniquement le XML d'installation)
    # -----------------------------------------------------------------------
    $btnUninstall.Add_Click({
        $idx = $dgLocalGames.SelectedIndex
        if ($idx -lt 0) { return }
        $game = $script:LocalGames[$idx]

        $confirm = [System.Windows.MessageBox]::Show(
            "Desinstaller '$($game.GameName)' ?`n`nLe fichier XML sera supprime mais le VHDX sera conserve.",
            "Confirmation de desinstallation", "YesNo", "Warning")
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

        try {
            if (Test-Path $game.XmlPath) {
                Remove-Item -Path $game.XmlPath -Force -ErrorAction Stop
                Write-GSLog "Jeu desinstalle : $($game.GameName)" -Level "INFO"
                $txtStatusBar.Text = "'$($game.GameName)' desinstalle."
            }
            & $loadLocalGames
        } catch {
            [System.Windows.MessageBox]::Show("Erreur lors de la desinstallation :`n$_", "Erreur", "OK", "Error")
        }
    })

    # -----------------------------------------------------------------------
    # Bouton Supprimer
    # -----------------------------------------------------------------------
    $btnDelete.Add_Click({
        $idx = $dgLocalGames.SelectedIndex
        if ($idx -lt 0) { return }
        $game = $script:LocalGames[$idx]

        $confirm = [System.Windows.MessageBox]::Show(
            "Supprimer '$($game.GameName)' ?`n`nLe dossier et le fichier VHDX seront definitivement supprimes.",
            "Confirmation de suppression", "YesNo", "Warning")
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

        try {
            # Demonter le VHDX s'il est monte
            $mounted = Get-MountedGSVhdxPath
            if ($mounted -eq $game.VhdxPath) {
                Dismount-GSVhdx
            }
            Remove-Item -Path $game.FolderPath -Recurse -Force -ErrorAction Stop
            Write-GSLog "Jeu supprime: $($game.GameName)" -Level "INFO"
            $txtStatusBar.Text = "'$($game.GameName)' supprime."
            & $loadLocalGames
        } catch {
            [System.Windows.MessageBox]::Show(
                "Erreur lors de la suppression :`n$_", "Erreur", "OK", "Error")
            Write-GSLog "Erreur suppression $($game.GameName): $_" -Level "ERROR"
        }
    })

    # -----------------------------------------------------------------------
    # Scan reseau
    # -----------------------------------------------------------------------
    $script:ScanJob    = $null
    $script:ScanTimer  = $null

    $btnScan.Add_Click({
        # Si un scan est en cours : l'arreter
        if ($null -ne $script:ScanJob -and $script:ScanJob.State -eq "Running") {
            if ($null -ne $script:ScanTimer) { $script:ScanTimer.Stop() }
            Stop-Job $script:ScanJob -ErrorAction SilentlyContinue
            Remove-Job $script:ScanJob -ErrorAction SilentlyContinue
            $script:ScanJob             = $null
            $pbScan.IsIndeterminate     = $false
            $pbScan.Value               = 0
            $btnScan.Content            = "  Scanner le reseau"
            $txtScanStatus.Text         = "Scan annule."
            $txtStatusBar.Text          = "Scan annule."
            return
        }

        # Nettoyer un job termine/failed residuel
        if ($null -ne $script:ScanJob) {
            Remove-Job $script:ScanJob -ErrorAction SilentlyContinue
            $script:ScanJob = $null
        }

        $btnScan.Content          = "  Arreter le scan"
        $pbScan.IsIndeterminate   = $true
        $txtScanStatus.Text       = "Scan du reseau en cours..."
        $dgPlayers.ItemsSource       = $null
        $dgRemoteGames.ItemsSource   = $null
        $txtRemoteReleaseYear.Text   = "-"
        $txtRemoteMaxPlayers.Text    = "-"
        $txtRemoteDesc.Text          = ""
        $imgRemoteThumb.Source       = $null
        $imgRemoteThumb.Visibility   = "Collapsed"
        $brdRemoteNoThumb.Visibility = "Visible"
        $btnRemoteWebsite.Visibility = "Collapsed"
        $btnDownload.IsEnabled       = $false
        $txtNetStatus.Text           = ""

        $netModPath   = Join-Path $ScriptDir "Modules\GS-Network.psm1"
        $logModPath   = Join-Path $ScriptDir "Modules\GS-Log.psm1"
        $currentAdapter = & $getSelectedAdapter
        $subnetStr    = if ($currentAdapter) { $currentAdapter.Subnet } else { "192.168.1.0/24" }
        $localIP      = if ($currentAdapter) { $currentAdapter.IPAddress } else { "" }
        Write-GSLog "Scan sur $subnetStr (carte: $($currentAdapter.InterfaceAlias))" -Level "INFO"

        $script:ScanJob = Start-Job -ScriptBlock {
            param($modNet, $modLog, $subnet)
            Import-Module $modLog  -Force
            Import-Module $modNet  -Force
            return Find-GSSharesOnNetwork -Subnet $subnet
        } -ArgumentList $netModPath, $logModPath, $subnetStr

        if ($null -ne $script:ScanTimer) {
            $script:ScanTimer.Stop()
        }
        $script:ScanTimer = [System.Windows.Threading.DispatcherTimer]::new()
        $script:ScanTimer.Interval = [TimeSpan]::FromMilliseconds(600)
        $script:ScanTimer.Add_Tick({
            if (-not $script:ScanJob) { $script:ScanTimer.Stop(); return }

            if ($script:ScanJob.State -eq "Completed") {
                $script:ScanTimer.Stop()
                $pbScan.IsIndeterminate = $false
                $pbScan.Value           = 100
                $btnScan.Content        = "  Scanner le reseau"

                $results = @(Receive-Job $script:ScanJob)
                Remove-Job $script:ScanJob
                $script:ScanJob = $null

                # Filtrer soi-meme
                $results = $results | Where-Object { $_.IPAddress -ne $localIP }

                $dgPlayers.ItemsSource = [object[]]@($results)
                $count = if ($results) { @($results).Count } else { 0 }
                $txtScanStatus.Text = if ($count -gt 0) { "$count joueur(s) trouve(s). Selectionnez un joueur." } `
                                      else { "Aucun joueur GameSwap trouve sur le reseau." }
                $txtScanCount.Text  = if ($count -gt 0) { "$count joueur(s)" } else { "" }
                $txtStatusBar.Text  = "Scan termine - $count joueur(s)."

            } elseif ($script:ScanJob.State -eq "Failed") {
                $script:ScanTimer.Stop()
                $pbScan.IsIndeterminate = $false
                $btnScan.Content        = "  Scanner le reseau"
                $txtScanStatus.Text     = "Le scan a echoue. Verifiez que nmap est installe."
                $txtStatusBar.Text      = "Erreur de scan."
                Remove-Job $script:ScanJob -ErrorAction SilentlyContinue
                $script:ScanJob = $null
            }
        })
        $script:ScanTimer.Start()
    })

    # -----------------------------------------------------------------------
    # Selection joueur -> afficher ses jeux
    # -----------------------------------------------------------------------
    $script:SelectedPlayer = $null
    $script:ListJob        = $null
    $script:ListTimer      = $null

    $dgPlayers.Add_SelectionChanged({
        $player = $dgPlayers.SelectedItem
        if (-not $player) {
            $dgRemoteGames.ItemsSource   = $null
            $txtRemoteReleaseYear.Text   = "-"
            $txtRemoteMaxPlayers.Text    = "-"
            $txtRemoteDesc.Text          = ""
            $imgRemoteThumb.Source       = $null
            $imgRemoteThumb.Visibility   = "Collapsed"
            $brdRemoteNoThumb.Visibility = "Visible"
            $btnRemoteWebsite.Visibility = "Collapsed"
            $btnDownload.IsEnabled       = $false
            $script:SelectedPlayer       = $null
            return
        }
        $script:SelectedPlayer = $player
        $txtNetStatus.Text     = "Chargement des jeux de $($player.PlayerName)..."

        $netModPath = Join-Path $ScriptDir "Modules\GS-Network.psm1"
        $logModPath = Join-Path $ScriptDir "Modules\GS-Log.psm1"
        $hostIP     = $player.IPAddress

        if ($null -ne $script:ListTimer) { $script:ListTimer.Stop() }
        if ($null -ne $script:ListJob)  {
            Stop-Job  $script:ListJob -ErrorAction SilentlyContinue
            Remove-Job $script:ListJob -ErrorAction SilentlyContinue
        }

        $script:ListJob = Start-Job -ScriptBlock {
            param($modNet, $modLog, $ip)
            Import-Module $modLog -Force
            Import-Module $modNet -Force
            return Get-RemoteGameList -HostIP $ip
        } -ArgumentList $netModPath, $logModPath, $hostIP

        $script:ListTimer = [System.Windows.Threading.DispatcherTimer]::new()
        $script:ListTimer.Interval = [TimeSpan]::FromMilliseconds(500)
        $script:ListTimer.Add_Tick({
            if ($null -eq $script:ListJob) { $script:ListTimer.Stop(); return }
            if ($script:ListJob.State -in @("Completed","Failed")) {
                $script:ListTimer.Stop()
                if ($script:ListJob.State -eq "Completed") {
                    $script:RemoteGames = @(Receive-Job $script:ListJob)
                    $remoteRows = $script:RemoteGames | ForEach-Object {
                        $r = $_
                        $mp  = if ($r.ExtraInfo -and $r.ExtraInfo.MaxPlayers) { $r.ExtraInfo.MaxPlayers } else { "-" }
                        $nom = if ($r.ExtraInfo -and -not [string]::IsNullOrWhiteSpace($r.ExtraInfo.DisplayName)) { $r.ExtraInfo.DisplayName } else { $r.GameName }
                        Add-Member -InputObject $r -NotePropertyName MaxJoueurs  -NotePropertyValue $mp  -Force
                        Add-Member -InputObject $r -NotePropertyName DisplayName -NotePropertyValue $nom -Force
                        $r
                    }
                    $remoteGames = $script:RemoteGames
                    $dgRemoteGames.ItemsSource = [object[]]@($remoteRows)
                    $count = if ($remoteGames) { @($remoteGames).Count } else { 0 }
                    $txtNetStatus.Text = "$count jeu(x) disponible(s) chez $($script:SelectedPlayer.PlayerName)."
                } else {
                    $txtNetStatus.Text = "Impossible de lister les jeux de $($script:SelectedPlayer.PlayerName)."
                }
                Remove-Job $script:ListJob -ErrorAction SilentlyContinue
                $script:ListJob = $null
                $btnDownload.IsEnabled = ($null -ne $dgRemoteGames.SelectedItem)
            }
        })
        $script:ListTimer.Start()
    })

    $dgRemoteGames.Add_SelectionChanged({
        $game = $dgRemoteGames.SelectedItem
        $btnDownload.IsEnabled = ($null -ne $game)

        if (-not $game) {
            $txtRemoteReleaseYear.Text   = "-"
            $txtRemoteMaxPlayers.Text    = "-"
            $txtRemoteDesc.Text          = ""
            $imgRemoteThumb.Source       = $null
            $imgRemoteThumb.Visibility   = "Collapsed"
            $brdRemoteNoThumb.Visibility = "Visible"
            $btnRemoteWebsite.Visibility = "Collapsed"
            return
        }

        $extra = $game.ExtraInfo

        $txtRemoteReleaseYear.Text = if ($extra -and -not [string]::IsNullOrWhiteSpace($extra.ReleaseYear)) { $extra.ReleaseYear } else { "-" }
        $txtRemoteMaxPlayers.Text = if ($extra -and $extra.MaxPlayers) { $extra.MaxPlayers } else { "-" }
        $txtRemoteDesc.Text       = if ($extra -and $extra.Description) { $extra.Description } else { "" }

        $trailer = if ($extra) { $extra.Trailer } else { "" }
        if (-not [string]::IsNullOrWhiteSpace($trailer)) {
            $script:RemoteTrailerUrl     = $trailer
            $btnRemoteWebsite.Visibility = "Visible"
        } else {
            $script:RemoteTrailerUrl     = ""
            $btnRemoteWebsite.Visibility = "Collapsed"
        }

        if ($game.ThumbBytes) {
            try {
                $ms  = New-Object System.IO.MemoryStream(,$game.ThumbBytes)
                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                $bmp.BeginInit()
                $bmp.CacheOption  = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $bmp.StreamSource = $ms
                $bmp.EndInit()
                $bmp.Freeze()
                $ms.Dispose()
                $imgRemoteThumb.Source       = $bmp
                $imgRemoteThumb.Visibility   = "Visible"
                $brdRemoteNoThumb.Visibility = "Collapsed"
            } catch {
                $imgRemoteThumb.Visibility   = "Collapsed"
                $brdRemoteNoThumb.Visibility = "Visible"
            }
        } else {
            $imgRemoteThumb.Source       = $null
            $imgRemoteThumb.Visibility   = "Collapsed"
            $brdRemoteNoThumb.Visibility = "Visible"
        }
    })

    # -----------------------------------------------------------------------
    # Bouton Telecharger + file d'attente automatique
    # -----------------------------------------------------------------------
    $script:DlHandle    = $null
    $script:DlTimer     = $null
    $script:QueueTimer  = $null

    # Scriptblock reutilisable : demarre le telechargement (slot deja acquis)
    $script:StartDownload = {
        param($remoteGame, $shareRootPath)

        $btnDownload.IsEnabled        = $false
        $btnCancelQueue.Visibility    = "Collapsed"
        $btnCancelDownload.Visibility = "Visible"
        $pbDownload.Value             = 0
        $pbDownload.Visibility        = "Visible"
        $txtDownloadStatus.Text       = "Connexion..."
        $txtDownloadStatus.Visibility = "Visible"
        $txtStatusBar.Text            = "Telechargement de '$($remoteGame.GameName)'..."

        $script:DlShareRootPath = $shareRootPath

        $script:DlHandle = Copy-RemoteGame `
            -RemoteVhdxPath $remoteGame.RemotePath `
            -LocalGamesFolder $script:GamesFolder `
            -GameName $remoteGame.GameName `
            -HostIP $remoteGame.HostIP `
            -PlayerName $Settings.PlayerName `
            -ShareRootPath $shareRootPath

        if ($null -ne $script:DlTimer) { $script:DlTimer.Stop() }
        $script:DlTimer = [System.Windows.Threading.DispatcherTimer]::new()
        $script:DlTimer.Interval = [TimeSpan]::FromMilliseconds(300)
        $gameName = $remoteGame.GameName
        $hostIP   = $remoteGame.HostIP

        $script:DlTimer.Add_Tick({
            $sync = $script:DlHandle.SyncHash
            $pbDownload.Value = $sync.Progress
            $statusParts = @("$($sync.Progress)%")
            if ($sync.Elapsed) { $statusParts += "Ecoule : $($sync.Elapsed)" }
            if ($sync.ETA)     { $statusParts += "Restant : $($sync.ETA)" }
            $txtDownloadStatus.Text = $statusParts -join "  |  "

            if ($sync.IsComplete) {
                $script:DlTimer.Stop()
                $pbDownload.Value      = 100
                $sharePath2 = "\\$($sync.HostIP)\GameSwap"
                cmd /c "net use $sharePath2 /DELETE /Y" 2>&1 | Out-Null

                if ($sync.HasError) {
                    [System.Windows.MessageBox]::Show(
                        "Erreur lors du telechargement :`n$($sync.ErrorMsg)",
                        "Erreur", "OK", "Error")
                    $txtStatusBar.Text = "Echec du telechargement."
                } else {
                    [System.Windows.MessageBox]::Show(
                        "'$($sync.GameName)' telecharge avec succes !`nVous pouvez maintenant l'installer depuis l'onglet Mes Jeux.",
                        "Telechargement termine", "OK", "Information")
                    $txtStatusBar.Text = "Telechargement termine."
                    & $loadLocalGames
                }

                $pbDownload.Visibility        = "Collapsed"
                $txtDownloadStatus.Visibility = "Collapsed"
                $btnCancelDownload.Visibility = "Collapsed"
                $btnDownload.IsEnabled        = ($null -ne $dgRemoteGames.SelectedItem)
            }
        })
        $script:DlTimer.Start()
    }

    $btnDownload.Add_Click({
        $remoteGame = $dgRemoteGames.SelectedItem
        if (-not $remoteGame) { return }

        # Verifier si un telechargement est deja en cours
        if ($script:DlHandle -and -not $script:DlHandle.SyncHash.IsComplete) {
            [System.Windows.MessageBox]::Show(
                "Un telechargement est deja en cours : '$($script:DlHandle.SyncHash.GameName)'.`nAttendez qu'il se termine avant d'en lancer un autre.",
                "Telechargement en cours", "OK", "Warning")
            return
        }

        # Verifier si en file d'attente
        if ($script:QueueTimer -and $script:QueueTimer.IsEnabled) {
            [System.Windows.MessageBox]::Show(
                "Le jeu '$($script:QueueGame.GameName)' est deja en file d'attente.`nCliquez sur 'Annuler l'attente' pour annuler.",
                "File d'attente active", "OK", "Warning")
            return
        }

        # Verifier si deja en local
        $localPath = Join-Path $script:GamesFolder "$($remoteGame.GameName)\$($remoteGame.GameName).vhdx"
        if (Test-Path $localPath) {
            $confirm = [System.Windows.MessageBox]::Show(
                "Le jeu '$($remoteGame.GameName)' est deja present en local.`nVoulez-vous le re-telecharger ?",
                "Confirmation", "YesNo", "Question")
            if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
        }

        # Connexion au partage
        $sharePath     = "\\$($remoteGame.HostIP)\GameSwap"
        $shareRootPath = $sharePath
        cmd /c "net use $sharePath /DELETE /Y" 2>&1 | Out-Null
        cmd /c "net use $sharePath /USER:GameSwap Edams-Bourbe0 /PERSISTENT:NO" 2>&1 | Out-Null

        # Tenter d'acquerir un slot
        $slotResult = Add-GSDownloadSlot -ShareRootPath $shareRootPath `
            -PlayerName $Settings.PlayerName -GameName $remoteGame.GameName

        if ($slotResult.Success) {
            # Slot obtenu : demarrer immediatement
            cmd /c "net use $sharePath /DELETE /Y" 2>&1 | Out-Null
            & $script:StartDownload $remoteGame $shareRootPath
        } else {
            # Slots pleins : proposer la file d'attente
            $queueFile  = "$shareRootPath\download_queue.json"
            $queueInfo  = Read-GSQueueInfo -QueueFile $queueFile
            $slotsUsed  = $queueInfo.slots.Count
            $maxS       = $queueInfo.maxSlots
            cmd /c "net use $sharePath /DELETE /Y" 2>&1 | Out-Null

            $confirm = [System.Windows.MessageBox]::Show(
                "Tous les slots sont utilises ($slotsUsed/$maxS).`n`nVoulez-vous etre mis en file d'attente ?`nLe telechargement demarrera automatiquement des qu'un slot se libere.",
                "Slots pleins", "YesNo", "Question")
            if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

            # Mettre en file d'attente
            $script:QueueGame       = $remoteGame
            $script:QueueSharePath  = $shareRootPath
            $btnDownload.IsEnabled  = $false
            $btnCancelQueue.Visibility    = "Visible"
            $txtDownloadStatus.Text       = "En attente d'un slot... ($slotsUsed/$maxS slots utilises)"
            $txtDownloadStatus.Visibility = "Visible"
            $txtStatusBar.Text            = "En file d'attente pour '$($remoteGame.GameName)'..."

            if ($null -ne $script:QueueTimer) { $script:QueueTimer.Stop() }
            $script:QueueTimer = [System.Windows.Threading.DispatcherTimer]::new()
            $script:QueueTimer.Interval = [TimeSpan]::FromSeconds(30)

            $script:QueueTimer.Add_Tick({
                $qGame      = $script:QueueGame
                $qSharePath = $script:QueueSharePath
                $queueFile2 = "$qSharePath\download_queue.json"

                # Se connecter brievement pour lire le fichier
                cmd /c "net use $qSharePath /DELETE /Y" 2>&1 | Out-Null
                cmd /c "net use $qSharePath /USER:GameSwap Edams-Bourbe0 /PERSISTENT:NO" 2>&1 | Out-Null

                $qInfo = Read-GSQueueInfo -QueueFile $queueFile2
                $used  = $qInfo.slots.Count
                $maxSl = $qInfo.maxSlots

                if ($used -lt $maxSl) {
                    # Slot disponible : tenter de l'acquerir
                    $res = Add-GSDownloadSlot -ShareRootPath $qSharePath `
                        -PlayerName $Settings.PlayerName -GameName $qGame.GameName
                    cmd /c "net use $qSharePath /DELETE /Y" 2>&1 | Out-Null

                    if ($res.Success) {
                        $script:QueueTimer.Stop()
                        $txtDownloadStatus.Text = "Slot obtenu ! Demarrage..."
                        & $script:StartDownload $qGame $qSharePath
                    } else {
                        # Quelqu'un d'autre a pris le slot en meme temps
                        $used = $res.Blockers.Count
                        $txtDownloadStatus.Text = "En attente d'un slot... ($used/$maxSl slots utilises)"
                        cmd /c "net use $qSharePath /DELETE /Y" 2>&1 | Out-Null
                    }
                } else {
                    $txtDownloadStatus.Text = "En attente d'un slot... ($used/$maxSl slots utilises)"
                    cmd /c "net use $qSharePath /DELETE /Y" 2>&1 | Out-Null
                }
            })
            $script:QueueTimer.Start()
        }
    })

    # Bouton Stopper le telechargement
    $btnCancelDownload.Add_Click({
        if ($null -ne $script:DlTimer) { $script:DlTimer.Stop() }

        if ($null -ne $script:DlHandle) {
            $gameName2    = $script:DlHandle.SyncHash.GameName
            $partialFile  = $script:DlHandle.SyncHash.DestFile

            # Arreter le runspace
            try { $script:DlHandle.PowerShell.Stop() } catch {}
            try { $script:DlHandle.Runspace.Close()  } catch {}

            # Supprimer le fichier partiel
            if ($partialFile -and (Test-Path $partialFile)) {
                Remove-Item $partialFile -Force -ErrorAction SilentlyContinue
                Write-GSLog "Telechargement annule, fichier partiel supprime: $partialFile" -Level "INFO"
            }

            # Liberer le slot manuellement (le finally du runspace ne s'executera pas)
            if ($gameName2 -and $script:DlShareRootPath) {
                $qPath = $script:DlShareRootPath
                cmd /c "net use $qPath /DELETE /Y" 2>&1 | Out-Null
                cmd /c "net use $qPath /USER:GameSwap Edams-Bourbe0 /PERSISTENT:NO" 2>&1 | Out-Null
                try {
                    Remove-GSDownloadSlot -ShareRootPath $qPath `
                        -PlayerName $Settings.PlayerName -GameName $gameName2
                } catch {}
                cmd /c "net use $qPath /DELETE /Y" 2>&1 | Out-Null
            }

            $script:DlHandle = $null
        }

        $pbDownload.Visibility        = "Collapsed"
        $txtDownloadStatus.Visibility = "Collapsed"
        $btnCancelDownload.Visibility = "Collapsed"
        $btnDownload.IsEnabled        = ($null -ne $dgRemoteGames.SelectedItem)
        $txtStatusBar.Text            = "Telechargement annule."
    })

    # Bouton Annuler l'attente
    $btnCancelQueue.Add_Click({
        if ($null -ne $script:QueueTimer) { $script:QueueTimer.Stop() }
        $script:QueueTimer             = $null
        $script:QueueGame              = $null
        $btnCancelQueue.Visibility     = "Collapsed"
        $txtDownloadStatus.Visibility  = "Collapsed"
        $btnDownload.IsEnabled         = ($null -ne $dgRemoteGames.SelectedItem)
        $txtStatusBar.Text             = "File d'attente annulee."
    })

    # -----------------------------------------------------------------------
    # Onglet Parametrage
    # -----------------------------------------------------------------------
    $txtSettingsPlayerName = $window.FindName("txtSettingsPlayerName")
    $btnApplyPlayerName    = $window.FindName("btnApplyPlayerName")
    $txtSettingsFolder     = $window.FindName("txtSettingsFolder")
    $btnBrowseFolder       = $window.FindName("btnBrowseFolder")
    $btnApplyFolder        = $window.FindName("btnApplyFolder")
    $dgSlots               = $window.FindName("dgSlots")
    $txtSlotsInfo          = $window.FindName("txtSlotsInfo")
    $btnRefreshSlots       = $window.FindName("btnRefreshSlots")
    $btnClearSlot          = $window.FindName("btnClearSlot")
    $txtSettingsStatus     = $window.FindName("txtSettingsStatus")
    $txtSlotsCount         = $window.FindName("txtSlotsCount")
    $btnSlotsDown          = $window.FindName("btnSlotsDown")
    $btnSlotsUp            = $window.FindName("btnSlotsUp")
    $btnApplySlots         = $window.FindName("btnApplySlots")
    $btnInstallVCRedist    = $window.FindName("btnInstallVCRedist")
    $btnInstallDirectX     = $window.FindName("btnInstallDirectX")

    # Pré-remplir les champs
    $txtSettingsPlayerName.Text = $Settings.PlayerName
    $txtSettingsFolder.Text     = $Settings.GameSwapFolder
    $txtSlotsCount.Text         = "$($Settings.MaxDownloadSlots)"

    $btnSlotsDown.Add_Click({
        $current = [int]$txtSlotsCount.Text
        if ($current -gt 1) { $txtSlotsCount.Text = "$($current - 1)" }
    })

    $btnSlotsUp.Add_Click({
        $current = [int]$txtSlotsCount.Text
        if ($current -lt 10) { $txtSlotsCount.Text = "$($current + 1)" }
    })

    $btnApplySlots.Add_Click({
        $newMax = [int]$txtSlotsCount.Text
        $Settings.MaxDownloadSlots = $newMax
        Save-GSSettings -Settings $Settings
        # Publier maxSlots dans download_queue.json (hote uniquement)
        if (-not [string]::IsNullOrWhiteSpace($Settings.GameSwapFolder)) {
            try {
                Set-GSQueueMaxSlots -ShareRootPath $Settings.GameSwapFolder -MaxSlots $newMax
            } catch {
                Write-GSLog "Impossible d'ecrire maxSlots dans la file : $_" -Level "WARNING"
            }
        }
        $txtSettingsStatus.Text = "Telechargements simultanes mis a jour : $newMax"
        Write-GSLog "Telechargements simultanes modifies : $newMax" -Level "INFO"
        & $loadSlots
    })

    # Fonction interne : recharger la liste des slots
    $loadSlots = {
        $myShareRoot = $Settings.GameSwapFolder
        if ([string]::IsNullOrWhiteSpace($myShareRoot)) { return }
        $slots = @(Get-GSDownloadQueue -ShareRootPath $myShareRoot)
        if ($slots.Count -eq 0) {
            $txtSlotsInfo.Text     = "Aucun telechargement en cours."
            $dgSlots.ItemsSource   = $null
            $btnClearSlot.IsEnabled = $false
        } else {
            $txtSlotsInfo.Text     = "$($slots.Count) / $($Settings.MaxDownloadSlots) slot(s) utilise(s)."
            $dgSlots.ItemsSource   = [object[]]@($slots)
        }
    }
    & $loadSlots

    $dgSlots.Add_SelectionChanged({
        $btnClearSlot.IsEnabled = ($null -ne $dgSlots.SelectedItem)
    })

    $btnRefreshSlots.Add_Click({ & $loadSlots })

    $btnClearSlot.Add_Click({
        $slot = $dgSlots.SelectedItem
        if (-not $slot) { return }
        $confirm = [System.Windows.MessageBox]::Show(
            "Liberer le slot de $($slot.PlayerName) ($($slot.GameName)) ?",
            "Confirmation", "YesNo", "Warning")
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
        Clear-GSDownloadSlot -ShareRootPath $Settings.GameSwapFolder -SlotIndex $dgSlots.SelectedIndex
        & $loadSlots
        $txtSettingsStatus.Text = "Slot libere."
    })

    # Appliquer le nom du joueur
    $btnApplyPlayerName.Add_Click({
        $newName = $txtSettingsPlayerName.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($newName) -or $newName.Length -gt 20 -or $newName -notmatch '^[a-zA-Z0-9]+$') {
            $txtSettingsStatus.Text = "Nom invalide (alphanumerique, 20 caracteres max)."
            return
        }
        $Settings.PlayerName = $newName
        Save-GSSettings -Settings $Settings
        # Mettre a jour gameswap_info.json
        Save-GSShareInfo -FolderPath $Settings.GameSwapFolder -PlayerName $newName
        # Mettre a jour le commentaire du partage SMB
        cmd /c "net share GameSwap /REMARK:""GameSwap|$newName""" 2>&1 | Out-Null
        $txtHeaderPlayer.Text   = $newName
        $txtSettingsStatus.Text = "Nom du joueur mis a jour : $newName"
        Write-GSLog "Nom du joueur modifie : $newName" -Level "INFO"
    })

    # Parcourir dossier
    $btnBrowseFolder.Add_Click({
        Add-Type -AssemblyName System.Windows.Forms
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description         = "Choisir le dossier GameSwap"
        $dlg.SelectedPath        = $txtSettingsFolder.Text
        $dlg.ShowNewFolderButton = $true
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtSettingsFolder.Text = $dlg.SelectedPath
        }
    })

    # Appliquer le dossier des jeux
    $btnApplyFolder.Add_Click({
        $newFolder = $txtSettingsFolder.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($newFolder)) {
            $txtSettingsStatus.Text = "Chemin invalide."
            return
        }
        $oldFolder = $Settings.GameSwapFolder
        if ($newFolder -eq $oldFolder) {
            $txtSettingsStatus.Text = "Le dossier est deja celui-ci."
            return
        }

        # Proposer de deplacer les jeux existants
        $moveGames = $false
        $oldJeux   = Join-Path $oldFolder "Jeux"
        if (Test-Path $oldJeux) {
            $ans = [System.Windows.MessageBox]::Show(
                "Voulez-vous deplacer les jeux existants vers le nouveau dossier ?`n`nOui = deplacer`nNon = nouveau dossier vide",
                "Dossier des jeux", "YesNo", "Question")
            $moveGames = ($ans -eq [System.Windows.MessageBoxResult]::Yes)
        }

        try {
            if (-not (Test-Path $newFolder)) {
                New-Item -ItemType Directory -Path $newFolder -Force | Out-Null
            }

            if ($moveGames) {
                $newJeux = Join-Path $newFolder "Jeux"
                $txtSettingsStatus.Text = "Deplacement des jeux en cours..."
                Move-Item -Path $oldJeux -Destination $newJeux -Force -ErrorAction Stop
                Write-GSLog "Jeux deplaces vers $newJeux" -Level "INFO"
            }

            $Settings.GameSwapFolder = $newFolder
            Save-GSSettings -Settings $Settings

            # Recrée le partage SMB sur le nouveau dossier
            New-GSShare -FolderPath $newFolder -PlayerName $Settings.PlayerName
            Set-GSQueueMaxSlots -ShareRootPath $newFolder -MaxSlots $Settings.MaxDownloadSlots

            $script:GamesFolder = Join-Path $newFolder "Jeux"
            $txtSettingsStatus.Text = "Dossier mis a jour. Partage SMB recree."
            Write-GSLog "Dossier GameSwap modifie : $newFolder" -Level "INFO"
            & $loadLocalGames
        } catch {
            $txtSettingsStatus.Text = "Erreur : $_"
            Write-GSLog "Erreur changement dossier : $_" -Level "ERROR"
        }
    })

    # -----------------------------------------------------------------------
    # Visual C++ Redistributables (toutes versions via winget)
    # -----------------------------------------------------------------------
    $btnInstallVCRedist.Add_Click({
        $scriptFile = Join-Path $env:TEMP "GS_Install_VCRedist.ps1"
        $scriptContent = @'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "=== GameSwap - Installation Visual C++ Redistributables ===" -ForegroundColor Cyan
Write-Host ""

$packages = @(
    [PSCustomObject]@{ Id = 'Microsoft.VCRedist.2005.x86'; Name = 'Visual C++ 2005 x86' },
    [PSCustomObject]@{ Id = 'Microsoft.VCRedist.2005.x64'; Name = 'Visual C++ 2005 x64' },
    [PSCustomObject]@{ Id = 'Microsoft.VCRedist.2008.x86'; Name = 'Visual C++ 2008 x86' },
    [PSCustomObject]@{ Id = 'Microsoft.VCRedist.2008.x64'; Name = 'Visual C++ 2008 x64' },
    [PSCustomObject]@{ Id = 'Microsoft.VCRedist.2010.x86'; Name = 'Visual C++ 2010 x86' },
    [PSCustomObject]@{ Id = 'Microsoft.VCRedist.2010.x64'; Name = 'Visual C++ 2010 x64' },
    [PSCustomObject]@{ Id = 'Microsoft.VCRedist.2012.x86'; Name = 'Visual C++ 2012 x86' },
    [PSCustomObject]@{ Id = 'Microsoft.VCRedist.2012.x64'; Name = 'Visual C++ 2012 x64' },
    [PSCustomObject]@{ Id = 'Microsoft.VCRedist.2013.x86'; Name = 'Visual C++ 2013 x86' },
    [PSCustomObject]@{ Id = 'Microsoft.VCRedist.2013.x64'; Name = 'Visual C++ 2013 x64' },
    [PSCustomObject]@{ Id = 'Microsoft.VCRedist.2015+.x86'; Name = 'Visual C++ 2015-2022 x86' },
    [PSCustomObject]@{ Id = 'Microsoft.VCRedist.2015+.x64'; Name = 'Visual C++ 2015-2022 x64' }
)

$ok = 0; $deja = 0; $fail = 0
foreach ($pkg in $packages) {
    Write-Host "--- $($pkg.Name) ---" -ForegroundColor Yellow
    winget install --id $pkg.Id --accept-package-agreements --accept-source-agreements
    $code = $LASTEXITCODE
    if ($code -eq 0) {
        $ok++
        Write-Host "  OK" -ForegroundColor Green
    } elseif ($code -eq -1978335189) {
        $deja++
        Write-Host "  Deja installe" -ForegroundColor DarkGray
    } else {
        $fail++
        Write-Host "  Avertissement (code $code)" -ForegroundColor DarkYellow
    }
    Write-Host ""
}

Write-Host "=== Termine : $ok installe(s)  $deja deja present(s)  $fail avertissement(s) ===" -ForegroundColor Cyan
Read-Host "`nAppuyez sur Entree pour fermer"
'@
        [System.IO.File]::WriteAllText($scriptFile, $scriptContent, [System.Text.Encoding]::UTF8)
        Start-Process "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptFile`""
    })

    # -----------------------------------------------------------------------
    # DirectX June 2010 (web installer)
    # -----------------------------------------------------------------------
    $btnInstallDirectX.Add_Click({
        $scriptFile = Join-Path $env:TEMP "GS_Install_DirectX.ps1"
        $scriptContent = @'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "=== GameSwap - Installation DirectX June 2010 ===" -ForegroundColor Cyan
Write-Host ""

$url  = "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe"
$dest = Join-Path $env:TEMP "dxwebsetup.exe"

try {
    Write-Host "Telechargement du web installer en cours..." -ForegroundColor Yellow
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    Write-Host "Telechargement termine." -ForegroundColor Green
    Write-Host ""
    Write-Host "Installation en cours (mode silencieux - evite la proposition barre Bing)..." -ForegroundColor Yellow
    Start-Process -FilePath $dest -ArgumentList "/Q" -Wait
    Remove-Item $dest -Force -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "=== Installation DirectX terminee ===" -ForegroundColor Cyan
} catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
}

Read-Host "`nAppuyez sur Entree pour fermer"
'@
        [System.IO.File]::WriteAllText($scriptFile, $scriptContent, [System.Text.Encoding]::UTF8)
        Start-Process "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptFile`""
    })

    # -----------------------------------------------------------------------
    # Nettoyage a la fermeture
    # -----------------------------------------------------------------------
    $window.Add_Closing({
        if ($script:ScanTimer)  { $script:ScanTimer.Stop() }
        if ($script:ScanJob)    { Stop-Job $script:ScanJob  -ErrorAction SilentlyContinue; Remove-Job $script:ScanJob  -ErrorAction SilentlyContinue }
        if ($script:ListTimer)  { $script:ListTimer.Stop() }
        if ($script:ListJob)    { Stop-Job $script:ListJob  -ErrorAction SilentlyContinue; Remove-Job $script:ListJob  -ErrorAction SilentlyContinue }
        if ($script:DlTimer)    { $script:DlTimer.Stop() }
        if ($script:QueueTimer) { $script:QueueTimer.Stop() }
        Write-GSLog "Fermeture de GameSwap" -Level "INFO"
    })

    [void]$window.ShowDialog()
}

Export-ModuleMember -Function Show-GSWizard, Show-GSMainWindow
